import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../../utils/app_logger.dart';
import '../../utils/image_cache_lru_store.dart';
import '../../utils/proxy_config.dart';
import 'jm_client.dart';
import 'jm_constants.dart';
import 'jm_image_decoder.dart';

// ignore_for_file: prefer_initializing_formals

class JmDecodedImageProvider extends ImageProvider<JmDecodedImageProvider> {
  final String url;
  final JmImageService service;
  final double scale;

  const JmDecodedImageProvider({
    required this.url,
    required this.service,
    this.scale = 1.0,
  });

  @override
  Future<JmDecodedImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<JmDecodedImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    JmDecodedImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
      debugLabel: key.url,
      informationCollector: () => [
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<JmDecodedImageProvider>('Image key', key),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    JmDecodedImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    final bytes = await key.service.loadDecodedBytes(key.url);
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) {
    return other is JmDecodedImageProvider &&
        other.url == url &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(url, scale);
}

class JmImageService {
  final Dio dio;
  final JmImageCache cache;
  final int maxConcurrent;
  final JmClient? _client;
  final _preferredHosts = <String, _PreferredHost>{};
  final _racedPrefixes = <String>{};
  final _backoffHosts = <String, _BackoffEntry>{};
  final _Semaphore _semaphore;
  final _pending = <String, Future<Uint8List>>{};

  static const _preferredTtl = Duration(minutes: 10);
  static const _backoffDuration = Duration(minutes: 5);
  static const _maxBackoffFailures = 2;
  static const _raceBatchSize = 2;

  JmImageService({
    required this.dio,
    JmImageCache? cache,
    this.maxConcurrent = 5,
    JmClient? client,
  }) : _client = client,
       cache = cache ?? JmImageCache(),
       _semaphore = _Semaphore(maxConcurrent);

  bool _isPreferredExpired(_PreferredHost host) {
    return DateTime.now().difference(host.selectedAt) > _preferredTtl;
  }

  bool _isInBackoff(String host) {
    final entry = _backoffHosts[host];
    if (entry == null) return false;
    if (entry.failureCount < _maxBackoffFailures) return false;
    if (DateTime.now().difference(entry.lastFailedAt) > _backoffDuration) {
      _backoffHosts.remove(host);
      return false;
    }
    return true;
  }

  void _recordFailure(String host) {
    final entry = _backoffHosts[host];
    if (entry == null) {
      _backoffHosts[host] = _BackoffEntry(failureCount: 1);
    } else {
      _backoffHosts[host] = _BackoffEntry(
        failureCount: entry.failureCount + 1,
        lastFailedAt: DateTime.now(),
      );
    }
  }

  void _recordSuccess(String host) {
    _backoffHosts.remove(host);
  }

  List<String> _availableImageDomains({String? exclude}) {
    final domains = _client?.imageDomains ?? const <String>[];
    return domains
        .where((d) => d != exclude && !_isInBackoff(d))
        .toList();
  }

  /// 为 [client] 创建独立的图片下载 Dio，避免挤占 API 连接的连接池，
  /// 并配置更宽松的超时以应对跨网 CDN 抖动。
  factory JmImageService.forClient(JmClient client, {String? proxyUrl}) {
    final imageDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 25),
        sendTimeout: const Duration(seconds: 8),
        persistentConnection: true,
        headers: {
          'user-agent': JmConstants.appUserAgent,
          'Accept': '*/*',
          'Accept-Encoding': 'gzip, deflate',
        },
      ),
    );

    configureDioProxy(imageDio, proxyUrl);

    imageDio.interceptors.addAll([
      _JmImageCookieInterceptor(client),
      _JmImageLoggingInterceptor(),
    ]);

    return JmImageService(dio: imageDio, client: client);
  }

  Future<Uint8List> loadDecodedBytes(String url) async {
    final cached = await cache.read(url);
    if (cached != null) return cached;

    final existing = _pending[url];
    if (existing != null) return existing;

    final future = _fetchAndDecode(url);
    _pending[url] = future;
    try {
      return await future;
    } finally {
      _pending.remove(url);
    }
  }

  Future<Uint8List> _fetchAndDecode(String url) async {
    await _semaphore.acquire();
    try {
      final metadata = JmImageMetadata.fromUrl(url);
      final rawBytes = await _fetchImageBytes(metadata.requestUri);
      if (rawBytes.isEmpty) {
        throw StateError('JM image response is empty');
      }

      // 封面图不需要做 JM 切割，直接缓存原字节。
      final decoded = metadata.isCover
          ? rawBytes
          : await compute(_decodeImageBytes, (
              bytes: rawBytes,
              photoId: metadata.photoId,
              filename: metadata.filenameWithoutExtension,
              scrambleId: metadata.scrambleId,
              isGif: metadata.isGif,
            ));
      await cache.write(url, decoded);
      return decoded;
    } finally {
      _semaphore.release();
    }
  }

  Future<Uint8List> _fetchImageBytes(Uri uri) async {
    if (_client != null && _isKnownImageHost(uri.host)) {
      final prefix = _imagePathPrefix(uri);

      // 优先使用上一次同类型图片测出来最快的域名（cover 和 photo 分开），并检查 TTL。
      final preferred = _preferredHosts[prefix];
      if (preferred != null && !_isPreferredExpired(preferred)) {
        final host = preferred.host;
        try {
          final bytes = await _fetchWithRetry(
            _uriForImageDomain(uri, host),
            maxRetries: 1,
          );
          _recordSuccess(host);
          return bytes;
        } catch (_) {
          // 优选域名对单张图片失败时，记录失败并尝试其他可用 CDN。
          _recordFailure(host);
          globalLogger.w(
            'JM IMG preferred host $host failed for ${uri.path}, '
            'trying other domains',
          );
          final fallback = await _fetchFromOtherDomains(
            uri,
            exclude: host,
          );
          if (fallback != null) {
            globalLogger.i(
              'JM IMG fallback succeeded: ${fallback.host} for ${uri.path}',
            );
            return fallback.bytes;
          }

          // 所有备用域名也都失败，清除过期优选并重新赛马。
          _preferredHosts.remove(prefix);
          final winner = await _raceImageDomains(uri);
          _preferredHosts[prefix] = _PreferredHost(host: winner.host);
          globalLogger.i(
            'JM IMG re-selected fastest host: ${winner.host} for $prefix',
          );
          return winner.bytes;
        }
      }

      // 优选过期时清除，避免使用陈旧的节点选择。
      if (preferred != null) {
        _preferredHosts.remove(prefix);
      }

      if (!_racedPrefixes.contains(prefix)) {
        _racedPrefixes.add(prefix);
        final winner = await _raceImageDomains(uri);
        _preferredHosts[prefix] = _PreferredHost(host: winner.host);
        globalLogger.i(
          'JM IMG selected fastest host: ${winner.host} for $prefix',
        );
        return winner.bytes;
      }
    }

    return _fetchWithRetry(uri, maxRetries: 2);
  }

  /// 顺序尝试除 [exclude] 外的其他可用图片域名，用于单张图片在当前 CDN 上损坏时的兜底。
  /// 处于退避期的域名会被跳过。
  Future<({Uint8List bytes, String host})?> _fetchFromOtherDomains(
    Uri uri, {
    required String exclude,
  }) async {
    final domains = _availableImageDomains(exclude: exclude);
    for (final domain in domains) {
      try {
        final bytes = await _fetchWithRetry(
          _uriForImageDomain(uri, domain),
          maxRetries: 1,
        );
        if (bytes.isNotEmpty) {
          _recordSuccess(domain);
          return (bytes: bytes, host: domain);
        }
      } catch (_) {
        _recordFailure(domain);
        // 继续尝试下一个域名
      }
    }
    return null;
  }

  /// 按图片类型（albums / photos / ...）做 key，避免 cover 选出来的域名
  /// 被直接套用到 photo 上（不同子域名的服务能力可能不同）。
  String _imagePathPrefix(Uri uri) {
    final segments = uri.pathSegments;
    final mediaIndex = segments.indexOf('media');
    if (mediaIndex >= 0 && mediaIndex + 1 < segments.length) {
      return segments[mediaIndex + 1];
    }
    return 'default';
  }

  /// 对同一个图片在可用图片域名之间分批并发赛马，每批 [_raceBatchSize] 个。
  /// 取第一个成功且非空的响应，降低瞬时并发量。
  Future<({Uint8List bytes, String host})> _raceImageDomains(
    Uri originalUri,
  ) async {
    final domains = _availableImageDomains();
    if (domains.isEmpty) {
      throw StateError('JM image domains are empty or all in backoff');
    }

    for (var i = 0; i < domains.length; i += _raceBatchSize) {
      final batch = domains.sublist(
        i,
        (i + _raceBatchSize).clamp(0, domains.length),
      );
      final tokens = <CancelToken>[];
      final futures = batch.map((domain) {
        final token = CancelToken();
        tokens.add(token);
        final uri = _uriForImageDomain(originalUri, domain);
        return _fetchOne(uri, cancelToken: token, receiveTimeoutMs: 8000)
            .then<({Uint8List bytes, String host})?>((bytes) {
              if (bytes.isNotEmpty) {
                for (final t in tokens) {
                  if (!t.isCancelled) t.cancel();
                }
                _recordSuccess(domain);
                return (bytes: bytes, host: domain);
              }
              return null;
            })
            .catchError((_) {
              _recordFailure(domain);
              return null;
            });
      }).toList();

      try {
        final winner = await Stream.fromFutures(
          futures,
        ).firstWhere((result) => result != null, orElse: () => null);
        if (winner != null) return winner;
      } finally {
        for (final t in tokens) {
          if (!t.isCancelled) t.cancel();
        }
        try {
          await Future.wait(futures, eagerError: false);
        } catch (_) {}
      }
    }

    throw StateError(
      'JM image download failed on all domains: ${domains.join(", ")}',
    );
  }

  bool _isKnownImageHost(String host) {
    return _client?.imageDomains.contains(host) ?? false;
  }

  Uri _uriForImageDomain(Uri original, String domain) {
    if (_client?.customImageHosts.contains(domain) ?? false) return original;
    return Uri(
      scheme: 'https',
      host: domain,
      path: original.path,
      queryParameters:
          original.queryParameters.isEmpty ? null : original.queryParameters,
    );
  }

  Future<Uint8List> _fetchOne(
    Uri uri, {
    CancelToken? cancelToken,
    int? receiveTimeoutMs,
  }) async {
    final options = Options(responseType: ResponseType.bytes);
    if (receiveTimeoutMs != null) {
      options.receiveTimeout = Duration(milliseconds: receiveTimeoutMs);
    }
    final response = await dio.getUri<List<int>>(
      uri,
      options: options,
      cancelToken: cancelToken,
    );
    return Uint8List.fromList(response.data ?? const []);
  }

  Future<Uint8List> _fetchWithRetry(Uri uri, {int maxRetries = 2}) async {
    var attempt = 0;
    while (true) {
      attempt++;
      try {
        final bytes = await _fetchOne(uri);
        if (bytes.isEmpty) {
          throw DioException(
            requestOptions: RequestOptions(path: uri.path),
            type: DioExceptionType.unknown,
            error: 'Empty image response',
          );
        }
        return bytes;
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;
        final shouldRetry =
            attempt <= maxRetries &&
            (e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout ||
                e.type == DioExceptionType.connectionError ||
                statusCode == null ||
                statusCode >= 500);
        if (!shouldRetry) rethrow;
        globalLogger.w('JM IMG retry ($attempt/$maxRetries) $uri -> ${e.type}');
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    }
  }
}

/// 简单的 Future 信号量，控制同时进行的图片下载数量，避免一次性
/// 发起几十张图片请求导致连接排队、乱序和超时。
class _Semaphore {
  final int _max;
  int _current = 0;
  final _queue = Queue<Completer<void>>();

  _Semaphore(this._max);

  Future<void> acquire() async {
    if (_current < _max) {
      _current++;
      return;
    }
    final completer = Completer<void>();
    _queue.add(completer);
    await completer.future;
  }

  void release() {
    if (_queue.isNotEmpty) {
      _queue.removeFirst().complete();
    } else {
      _current--;
    }
  }
}

/// 让图片下载 Dio 共享 JM 登录/年龄验证 Cookie。
class _JmImageCookieInterceptor extends Interceptor {
  final JmClient client;

  _JmImageCookieInterceptor(this.client);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final cookie = client.cookieHeader;
    if (cookie.isNotEmpty) {
      options.headers['Cookie'] = cookie;
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _captureCookies(response.headers);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _captureCookies(err.response?.headers);
    handler.next(err);
  }

  void _captureCookies(Headers? headers) {
    final list = headers?['set-cookie'];
    if (list == null || list.isEmpty) return;

    final parsed = Map<String, String>.from(client.cookies);
    for (final raw in list) {
      final first = raw.split(';').first.trim();
      final idx = first.indexOf('=');
      if (idx > 0 && idx < first.length - 1) {
        final name = first.substring(0, idx).trim();
        final value = first.substring(idx + 1).trim();
        if (name.isNotEmpty && value.isNotEmpty) {
          parsed[name] = value;
        }
      }
    }
    if (parsed.isNotEmpty) {
      client.setCookies(parsed);
    }
  }
}

class _JmImageLoggingInterceptor extends Interceptor {
  static const _startKey = 'jm_img_req_start_ms';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now().millisecondsSinceEpoch;
    globalLogger.d('JM IMG REQ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final req = response.requestOptions;
    final elapsed = _elapsedMs(req);
    if (kReleaseMode) {
      globalLogger.d(
        'JM IMG RES ${req.method} ${req.uri} -> ${response.statusCode} (${elapsed}ms)',
      );
    } else {
      globalLogger.d(
        'JM IMG RES ${req.method} ${req.uri} -> ${response.statusCode} '
        '(${response.data?.length ?? 0} bytes, ${elapsed}ms)',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final req = err.requestOptions;
    final elapsed = _elapsedMs(req);
    globalLogger.e(
      'JM IMG ERR ${req.method} ${req.uri} -> '
      '${err.response?.statusCode ?? err.type} (${elapsed}ms)',
      error: err.message,
    );
    handler.next(err);
  }

  int _elapsedMs(RequestOptions options) {
    final start = options.extra[_startKey] as int?;
    if (start == null) return -1;
    return DateTime.now().millisecondsSinceEpoch - start;
  }
}

class JmImageMetadata {
  final Uri requestUri;
  final int photoId;
  final String filenameWithoutExtension;
  final int scrambleId;
  final bool isGif;
  final bool isCover;

  const JmImageMetadata({
    required this.requestUri,
    required this.photoId,
    required this.filenameWithoutExtension,
    required this.scrambleId,
    required this.isGif,
    required this.isCover,
  });

  factory JmImageMetadata.fromUrl(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    final photosIndex = segments.indexOf('photos');
    final albumsIndex = segments.indexOf('albums');

    final int photoId;
    final String filename;
    final bool isCover;
    if (photosIndex >= 0 && photosIndex + 2 < segments.length) {
      photoId = int.parse(segments[photosIndex + 1]);
      filename = segments[photosIndex + 2];
      isCover = false;
    } else if (albumsIndex >= 0 && albumsIndex + 1 < segments.length) {
      // 封面图：/media/albums/{aid}{size}.jpg
      final rawId = segments[albumsIndex + 1].split('_').first;
      photoId = int.tryParse(rawId) ?? 0;
      filename = segments[albumsIndex + 1];
      isCover = true;
    } else {
      throw FormatException('Unsupported JM image url: $url');
    }

    final dot = filename.lastIndexOf('.');
    final filenameWithoutExtension = dot <= 0
        ? filename
        : filename.substring(0, dot);
    final query = Map<String, String>.from(uri.queryParameters)
      ..remove('scramble_id');
    final scrambleId = isCover
        ? JmConstants.scramble220980
        : (int.tryParse(uri.queryParameters['scramble_id'] ?? '') ??
              JmConstants.scramble220980);

    return JmImageMetadata(
      requestUri: uri.replace(queryParameters: query.isEmpty ? null : query),
      photoId: photoId,
      filenameWithoutExtension: filenameWithoutExtension,
      scrambleId: scrambleId,
      isGif: filename.toLowerCase().endsWith('.gif'),
      isCover: isCover,
    );
  }
}

class JmImageCache {
  static const _maxCoverBytes = 256 * 1024 * 1024;
  static const _maxImageBytes = 512 * 1024 * 1024;
  static const _coverStaleDays = 14;
  static const _imageStaleDays = 7;

  final ImageCacheLruStore _lru;
  Directory? _decodedDir;
  Directory? _coverDir;

  JmImageCache({ImageCacheLruStore? lru}) : _lru = lru ?? ImageCacheLruStore();

  Future<Uint8List?> read(String key) async {
    final file = await _fileFor(key);
    if (!await file.exists()) return null;
    await _lru.touch(_lruKeyFor(key));
    return file.readAsBytes();
  }

  Future<void> write(String key, Uint8List bytes) async {
    final file = await _fileFor(key);
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsBytes(bytes, flush: true);
    await temp.rename(file.path);
    await _lru.touch(_lruKeyFor(key));
    await _evictIfNeeded(_isCoverUrl(key));
  }

  /// 主动触发缓存清理。应用冷启动时调用一次即可。
  Future<void> evictIfNeeded() async {
    await _evictIfNeeded(true);
    await _evictIfNeeded(false);
  }

  Future<void> _evictIfNeeded(bool cover) async {
    final dir = await _directoryFor(cover);
    if (!await dir.exists()) return;

    final maxBytes = cover ? _maxCoverBytes : _maxImageBytes;
    final staleDays = cover ? _coverStaleDays : _imageStaleDays;
    final staleThreshold = DateTime.now()
        .subtract(Duration(days: staleDays))
        .millisecondsSinceEpoch;

    final lru = await _lru.readAll();
    final entries = <_CacheEntry>[];
    final urlsToRemoveFromLru = <String>[];
    var totalSize = 0;

    await for (final entity in dir.list(recursive: false, followLinks: false)) {
      if (entity is! File) continue;
      final url = _lruKeyForFile(entity, cover);
      final size = await entity.length();
      totalSize += size;
      final lastAccess = lru[url];
      if (lastAccess == null) {
        // 文件存在但 LRU 中没有：补录为当前时间，避免误删。
        entries.add(_CacheEntry(url, entity, size, DateTime.now().millisecondsSinceEpoch));
      } else {
        entries.add(_CacheEntry(url, entity, size, lastAccess));
      }
    }

    // 同步 LRU：删除 map 中已不存在的文件记录。
    for (final url in lru.keys) {
      final exists = entries.any((e) => e.url == url);
      if (!exists) urlsToRemoveFromLru.add(url);
    }
    if (urlsToRemoveFromLru.isNotEmpty) {
      await _lru.removeAll(urlsToRemoveFromLru);
    }

    // 补充新发现的文件到 LRU。
    final newUrls = <String, int>{};
    for (final entry in entries) {
      if (!lru.containsKey(entry.url)) {
        newUrls[entry.url] = entry.lastAccess;
      }
    }
    if (newUrls.isNotEmpty) {
      lru.addAll(newUrls);
      await _lru.writeAll(lru);
    }

    // 智能清理：删除过期未访问文件。
    entries.sort((a, b) => a.lastAccess.compareTo(b.lastAccess));
    final staleEntries = entries.where((e) => e.lastAccess < staleThreshold).toList();
    for (final entry in staleEntries) {
      try {
        await entry.file.delete();
        totalSize -= entry.size;
        entries.remove(entry);
        lru.remove(entry.url);
      } catch (_) {
        // ignore
      }
    }

    // 容量清理：按 LRU 删除到上限的 80%。
    final targetBytes = (maxBytes * 0.8).round();
    while (totalSize > maxBytes && entries.isNotEmpty) {
      final oldest = entries.first;
      try {
        await oldest.file.delete();
        totalSize -= oldest.size;
        entries.removeAt(0);
        lru.remove(oldest.url);
      } catch (_) {
        entries.removeAt(0);
      }
    }

    // 确保不超过目标上限（80%）。
    while (totalSize > targetBytes && entries.isNotEmpty) {
      final oldest = entries.first;
      try {
        await oldest.file.delete();
        totalSize -= oldest.size;
        entries.removeAt(0);
        lru.remove(oldest.url);
      } catch (_) {
        entries.removeAt(0);
      }
    }

    await _lru.writeAll(lru);
  }

  String _lruKeyFor(String url) {
    final digest = md5.convert(Uint8List.fromList(url.codeUnits)).toString();
    return _isCoverUrl(url) ? 'cover:$digest' : 'image:$digest';
  }

  String _lruKeyForFile(File file, bool cover) {
    final digest = basename(file.path).replaceAll('.jpg', '');
    return cover ? 'cover:$digest' : 'image:$digest';
  }

  Future<File> _fileFor(String key) async {
    final directory = await _directoryFor(_isCoverUrl(key));
    final digest = md5.convert(Uint8List.fromList(key.codeUnits)).toString();
    return File('${directory.path}/$digest.jpg');
  }

  Future<Directory> _directoryFor(bool cover) async {
    if (cover) {
      return _coverDir ??= Directory(
        '${(await getTemporaryDirectory()).path}/jm_covers',
      );
    }
    return _decodedDir ??= Directory(
      '${(await getTemporaryDirectory()).path}/jm_decoded_images',
    );
  }

  static bool _isCoverUrl(String url) {
    if (url.contains('/api/v1/covers/')) return true;
    try {
      return JmImageMetadata.fromUrl(url).isCover;
    } catch (_) {
      return false;
    }
  }
}

class _CacheEntry {
  final String url;
  final File file;
  final int size;
  final int lastAccess;

  _CacheEntry(this.url, this.file, this.size, this.lastAccess);
}

Uint8List decodeJmImageBytesForTest({
  required Uint8List bytes,
  required int photoId,
  required String filename,
  required int scrambleId,
  bool isGif = false,
}) {
  return _decodeImageBytes((
    bytes: bytes,
    photoId: photoId,
    filename: filename,
    scrambleId: scrambleId,
    isGif: isGif,
  ));
}

Uint8List _decodeImageBytes(
  ({Uint8List bytes, int photoId, String filename, int scrambleId, bool isGif})
  input,
) {
  if (input.isGif) {
    return input.bytes;
  }

  final segmentCount = JmImageDecoder.segmentationCount(
    scrambleId: input.scrambleId,
    aid: input.photoId,
    filename: input.filename,
  );
  if (segmentCount <= 1) {
    return input.bytes;
  }

  final source = img.decodeImage(input.bytes);
  if (source == null) {
    return input.bytes;
  }

  final restoredBytes = JmImageDecoder.restoreVerticalSegments(
    pixels: source.getBytes(),
    rowStride: source.rowStride,
    height: source.height,
    segmentCount: segmentCount,
  );
  final restored = img.Image.fromBytes(
    width: source.width,
    height: source.height,
    bytes: restoredBytes.buffer,
    numChannels: source.numChannels,
    rowStride: source.rowStride,
  );

  return Uint8List.fromList(img.encodeJpg(restored, quality: 95));
}

class _PreferredHost {
  final String host;
  final DateTime selectedAt;

  _PreferredHost({required this.host, DateTime? selectedAt})
    : selectedAt = selectedAt ?? DateTime.now();
}

class _BackoffEntry {
  final int failureCount;
  final DateTime lastFailedAt;

  _BackoffEntry({required this.failureCount, DateTime? lastFailedAt})
    : lastFailedAt = lastFailedAt ?? DateTime.now();
}

