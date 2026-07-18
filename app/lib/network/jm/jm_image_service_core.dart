import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../utils/app_logger.dart';
import '../../utils/proxy_config.dart';
import 'jm_client.dart';
import 'jm_constants.dart';
import 'jm_image_cache.dart';
import 'jm_image_decoder.dart';
import 'jm_image_interceptors.dart';
import 'jm_image_metadata.dart';
import 'jm_image_semaphore.dart';

// ignore_for_file: prefer_initializing_formals

class JmImageService {
  final Dio dio;
  final JmImageCache cache;
  final int maxConcurrent;
  final JmClient? _client;
  final bool _ownsDio;
  bool _closed = false;
  final _preferredHosts = <String, _PreferredHost>{};
  final _backoffHosts = <String, _BackoffEntry>{};
  final JmImageSemaphore _semaphore;
  final _pending = <String, Future<Uint8List>>{};
  final _scrambleIds = <int, Future<int>>{};

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
       _ownsDio = false,
       cache = cache ?? JmImageCache(),
       _semaphore = JmImageSemaphore(maxConcurrent);

  /// 由 [JmImageService.forClient] 使用：dio 为内部创建，生命周期归本实例管理。
  JmImageService._owned({
    required this.dio,
    JmImageCache? cache,
    this.maxConcurrent = 5,
    JmClient? client,
  }) : _client = client,
       _ownsDio = true,
       cache = cache ?? JmImageCache(),
       _semaphore = JmImageSemaphore(maxConcurrent);

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

  /// 清除所有图片域名的退避状态。
  ///
  /// 用户手动点击重试时调用，让之前失败的域名能够重新参与赛马。
  void clearBackoff() {
    _backoffHosts.clear();
  }

  /// 内部图片 Dio 是否已通过 [close] 关闭。
  @visibleForTesting
  bool get isClosed => _closed;

  /// 关闭内部创建的图片 Dio，释放连接池中的空闲连接。
  ///
  /// 配置变更导致 repository 重建时由 provider 的 dispose 钩子调用，
  /// 避免旧实例的连接长期累积。外部注入的 dio 由调用方自行管理，
  /// 此处不会关闭。幂等，可重复调用；关闭后该实例不应再发起请求。
  void close() {
    if (_closed) return;
    _closed = true;
    if (!_ownsDio) return;
    // force: false，让在途请求正常完成，仅拒绝新请求。
    dio.close();
  }

  List<String> _availableImageDomains({String? exclude}) {
    final domains = _client?.imageDomains ?? const <String>[];
    return domains.where((d) => d != exclude && !_isInBackoff(d)).toList();
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
      JmImageCookieInterceptor(client),
      JmImageLoggingInterceptor(),
    ]);

    return JmImageService._owned(dio: imageDio, client: client);
  }

  Future<Uint8List> loadDecodedBytes(String url) async {
    final cached = await cache.read(url);
    if (cached != null) return cached;

    final pendingKey = cache.pendingKeyFor(url);
    final existing = _pending[pendingKey];
    if (existing != null) return existing;

    final future = _fetchAndDecode(url);
    _pending[pendingKey] = future;
    try {
      return await future;
    } finally {
      _pending.remove(pendingKey);
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
      final scrambleId = metadata.isCover || metadata.hasScrambleId
          ? metadata.scrambleId
          : await _scrambleIdFor(metadata.photoId);

      // 封面图不需要做 JM 切割，直接缓存原字节。
      final decoded = metadata.isCover
          ? rawBytes
          : await compute(_decodeImageBytes, (
              bytes: rawBytes,
              photoId: metadata.photoId,
              filename: metadata.filenameWithoutExtension,
              scrambleId: scrambleId,
              isGif: metadata.isGif,
            ));
      await cache.write(url, decoded);
      return decoded;
    } finally {
      _semaphore.release();
    }
  }

  Future<int> _scrambleIdFor(int photoId) {
    final client = _client;
    if (client == null) {
      return Future.value(JmConstants.scramble220980);
    }
    return _scrambleIds[photoId] ??= client.getScrambleId(photoId.toString());
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
          final fallback = await _fetchFromOtherDomains(uri, exclude: host);
          if (fallback != null) {
            globalLogger.i(
              'JM IMG fallback succeeded: ${fallback.host} for ${uri.path}',
            );
            return fallback.bytes;
          }

          // 所有备用域名也都失败，清除过期优选并重新赛马。
          _preferredHosts.remove(prefix);
        }
      } else if (preferred != null) {
        // 优选过期时清除，避免使用陈旧的节点选择。
        _preferredHosts.remove(prefix);
      }

      // 没有有效优选时，重新在所有可用域名间赛马，确保失败重试也能切换域名。
      final winner = await _raceImageDomains(uri);
      _preferredHosts[prefix] = _PreferredHost(host: winner.host);
      globalLogger.i(
        'JM IMG selected fastest host: ${winner.host} for $prefix',
      );
      return winner.bytes;
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

  /// 对 [domains] 分批并发赛马，取第一个成功且非空的响应。
  Future<({Uint8List bytes, String host})> _raceDomainBatches(
    Uri originalUri,
    List<String> domains,
  ) async {
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
      'JM image download failed on domains: ${domains.join(", ")}',
    );
  }

  /// 对同一个图片在可用图片域名之间分批并发赛马，每批 [_raceBatchSize] 个。
  /// 取第一个成功且非空的响应，降低瞬时并发量。
  /// 当用户配置了自定义图片域名时，优先只在自定义域名间赛马；全部失败后再回退到官方 CDN。
  Future<({Uint8List bytes, String host})> _raceImageDomains(
    Uri originalUri,
  ) async {
    final allDomains = _availableImageDomains();
    if (allDomains.isEmpty) {
      throw StateError('JM image domains are empty or all in backoff');
    }

    final customHosts = _client?.customImageHosts ?? const <String>{};
    final customDomains = allDomains
        .where((d) => customHosts.contains(d))
        .toList();
    final officialDomains = allDomains
        .where((d) => !customHosts.contains(d))
        .toList();

    // 优先在自定义图片域名之间赛马。
    if (customDomains.isNotEmpty) {
      try {
        return await _raceDomainBatches(originalUri, customDomains);
      } catch (_) {
        globalLogger.w(
          'JM IMG custom domains failed for ${originalUri.path}, '
          'falling back to official CDN',
        );
      }
    }

    // 自定义域名全部失败或不可用时，回退到官方 CDN。
    if (officialDomains.isNotEmpty) {
      return await _raceDomainBatches(originalUri, officialDomains);
    }

    throw StateError(
      'JM image download failed on all domains: ${allDomains.join(", ")}',
    );
  }

  bool _isKnownImageHost(String host) {
    return _client?.imageDomains.contains(host) ?? false;
  }

  Uri _uriForImageDomain(Uri original, String domain) {
    final customUri = _client?.customImageUriByHost[domain];
    if (customUri != null) {
      return customUri.replace(
        path: original.path,
        queryParameters: original.queryParameters.isEmpty
            ? null
            : original.queryParameters,
      );
    }
    return Uri(
      scheme: 'https',
      host: domain,
      path: original.path,
      queryParameters: original.queryParameters.isEmpty
          ? null
          : original.queryParameters,
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
