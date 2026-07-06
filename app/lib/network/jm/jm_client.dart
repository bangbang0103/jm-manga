import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../utils/app_logger.dart';
import '../../utils/proxy_config.dart';
import 'jm_constants.dart';
import 'jm_crypto.dart';
import 'jm_domain.dart';
import 'jm_domain_updater.dart';
import 'jm_models.dart';

typedef TimestampProvider = int Function();

const _setCookieHeader = 'set-cookie';

class JmClient {
  static const searchPath = '/search';
  static const albumPath = '/album';
  static const chapterPath = '/chapter';
  static const chapterViewTemplatePath = '/chapter_view_template';
  static const categoriesFilterPath = '/categories/filter';
  static const loginPath = '/login';
  static const favoritePath = '/favorite';

  final Dio dio;
  final TimestampProvider timestampProvider;
  final JmDomainUpdater? _domainUpdater;
  final bool _autoUpdateDomains;
  final Map<String, String> _cookies = {};

  List<String> _apiDomains;
  List<String> _imageDomains;
  int _apiDomainIndex = 0;
  int _imageDomainIndex = 0;
  bool _domainsUpdated = false;
  Future<void>? _domainUpdateFuture;
  final _scrambleIdFutures = <String, Future<int>>{};
  final List<Uri> _customApiUris;
  final List<Uri> _customImageUris;

  JmDomainConfig get domains => _currentDomainConfig();

  List<String> get apiDomains => _apiDomains;

  List<String> get imageDomains => _imageDomains;

  Set<String> get customApiHosts => _customApiUris.map((u) => u.host).toSet();

  Set<String> get customImageHosts =>
      _customImageUris.map((u) => u.host).toSet();

  /// Mapping from custom image domain host to its full configured URI.
  ///
  /// Used by the image service to rebuild image URLs for each custom domain
  /// during domain racing, preserving the original scheme, host and port.
  Map<String, Uri> get customImageUriByHost => {
    for (final uri in _customImageUris) uri.host: uri,
  };

  /// Parse a list of domain strings into URIs and return their hosts.
  static Iterable<String> _parseHosts(List<String> domains) {
    return domains.map(Uri.parse).map((u) => u.host);
  }

  /// Merge [preferred] domains with [fallback] domains, keeping preferred first
  /// and removing duplicates while preserving order.
  static List<String> _mergeDomains(
    Iterable<String> preferred,
    Iterable<String> fallback,
  ) {
    final result = <String>[];
    final seen = <String>{};
    for (final domain in preferred) {
      if (seen.add(domain)) result.add(domain);
    }
    for (final domain in fallback) {
      if (seen.add(domain)) result.add(domain);
    }
    return result;
  }

  int get currentApiDomainIndex => _apiDomainIndex;

  void selectApiDomain(int index) {
    if (index >= 0 && index < _apiDomains.length) {
      _apiDomainIndex = index;
    }
  }

  JmClient({
    Dio? dio,
    JmDomainConfig? domains,
    TimestampProvider? timestampProvider,
    JmDomainUpdater? domainUpdater,
    bool autoUpdateDomains = true,
    String? proxyUrl,
    List<String> customApiDomains = const <String>[],
    List<String> customImageDomains = const <String>[],
  }) : dio = dio ?? Dio(),
       timestampProvider =
           timestampProvider ??
           (() => DateTime.now().millisecondsSinceEpoch ~/ 1000),
       // ignore: prefer_initializing_formals
       _domainUpdater = domainUpdater,
       // Keep the public API name readable while storing the private flag.
       // ignore: prefer_initializing_formals
       _autoUpdateDomains = autoUpdateDomains,
       _customApiUris = List.unmodifiable(
         customApiDomains.map(Uri.parse).toList(),
       ),
       _customImageUris = List.unmodifiable(
         customImageDomains.map(Uri.parse).toList(),
       ),
       _apiDomains = List.unmodifiable(
         _mergeDomains(
           _parseHosts(customApiDomains),
           domains?.apiDomains ?? JmConstants.apiDomains,
         ),
       ),
       _imageDomains = List.unmodifiable(
         _mergeDomains(
           _parseHosts(customImageDomains),
           domains?.imageDomains ?? JmConstants.imageDomains,
         ),
       ) {
    this.dio.interceptors.add(_JmLoggingInterceptor());
    // 尽量复用连接：长连接 + 合理超时。
    this.dio.options = this.dio.options.copyWith(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 8),
      persistentConnection: true,
    );
    configureDioProxy(this.dio, proxyUrl);
  }

  /// 确保域名列表已经过动态更新。
  ///
  /// 首次调用时会从域名服务器拉取最新可用域名并缓存；后续调用直接返回。
  /// 该方法由 [JmClient] 内部在发起请求前自动调用，也可由外部提前预加载。
  /// 构造时设置 [autoUpdateDomains] 为 false 可禁用自动更新。
  Future<void> ensureDomainsUpdated() async {
    if (_domainsUpdated || !_autoUpdateDomains) return;

    // 所有首次请求共享同一次域名更新，避免在更新完成前就用 fallback 域名并发请求。
    _domainUpdateFuture ??= _fetchDomainConfigOnce();
    await _domainUpdateFuture;
  }

  Future<void> _fetchDomainConfigOnce() async {
    final updater = _domainUpdater ?? JmDomainUpdater(dio: dio);
    try {
      final config = await updater.fetchDomainConfig();
      _applyDomainConfig(config);
    } catch (_) {
      // 动态更新失败不影响既有回退域名，错误已在 updater 内记录。
      // 保留 fallback 域名继续尝试，避免首次请求直接崩溃。
    } finally {
      _domainsUpdated = true;
      _domainUpdateFuture = null;
    }
  }

  void _applyDomainConfig(JmDomainConfig config) {
    // 自定义域名优先；动态更新返回的官方域名作为兜底，避免自定义节点异常时完全不可用。
    if (config.apiDomains.isNotEmpty) {
      _apiDomains = List.unmodifiable(
        _mergeDomains(_customApiUris.map((u) => u.host), config.apiDomains),
      );
      _apiDomainIndex = 0;
    }
    if (config.imageDomains.isNotEmpty) {
      _imageDomains = List.unmodifiable(
        _mergeDomains(_customImageUris.map((u) => u.host), config.imageDomains),
      );
      _imageDomainIndex = 0;
    }
  }

  JmDomainConfig _currentDomainConfig() {
    final apiScheme = _apiDomainIndex < _customApiUris.length
        ? _customApiUris[_apiDomainIndex].scheme
        : 'https';
    return JmDomainConfig(
      apiDomains: [_apiDomains[_apiDomainIndex]],
      imageDomains: [_imageDomains[_imageDomainIndex]],
      scheme: apiScheme,
    );
  }

  Uri _buildApiUri(
    String path, {
    Map<String, Object?> queryParameters = const {},
  }) {
    if (_apiDomainIndex < _customApiUris.length) {
      return _customApiUris[_apiDomainIndex].replace(
        path: path,
        queryParameters: JmDomainConfig.cleanQuery(queryParameters),
      );
    }
    return domains.apiUri(path, queryParameters: queryParameters);
  }

  String _buildImageUrl(
    String path, {
    Map<String, Object?> queryParameters = const {},
  }) {
    if (_imageDomainIndex < _customImageUris.length) {
      return _customImageUris[_imageDomainIndex]
          .replace(
            path: path,
            queryParameters: JmDomainConfig.cleanQuery(queryParameters),
          )
          .toString();
    }
    return domains.imageUri(path, queryParameters: queryParameters).toString();
  }

  bool _canSwitchApiDomain() => _apiDomainIndex + 1 < _apiDomains.length;

  void _switchApiDomain() {
    _advanceDomainOrReset();
  }

  Map<String, String> headersFor(String path, int timestamp) {
    final token = JmCrypto.tokenAndTokenParam(
      timestamp,
      secret: path == chapterViewTemplatePath
          ? JmConstants.appTokenSecretForContent
          : JmConstants.appTokenSecret,
    );
    final headers = {
      'Accept-Encoding': 'gzip, deflate',
      'user-agent': JmConstants.appUserAgent,
      'token': token.token,
      'tokenparam': token.tokenParam,
    };
    final cookie = cookieHeader;
    if (cookie.isNotEmpty) {
      headers['Cookie'] = cookie;
    }
    return headers;
  }

  Map<String, String> get cookies => Map.unmodifiable(_cookies);

  String get cookieHeader {
    if (_cookies.isEmpty) return '';
    return _cookies.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('; ');
  }

  void setCookies(Map<String, String> cookies) {
    _cookies
      ..clear()
      ..addAll(cookies);
  }

  void clearCookies() {
    _cookies.clear();
  }

  Uri uriFor(String path, {Map<String, Object?> queryParameters = const {}}) {
    return _buildApiUri(path, queryParameters: queryParameters);
  }

  Future<JmSearchPage> search(String query, {int page = 1}) async {
    final data = await _getDecodedJson(searchPath, {
      'main_tag': 0,
      'search_query': query,
      'page': page,
      'o': 'mr',
      't': 'a',
    });
    if (data['redirect_aid'] != null) {
      final album = await getAlbum(data['redirect_aid'].toString());
      return JmSearchPage(
        total: 1,
        items: [JmListItem(id: album.id, title: album.title, tags: album.tags)],
      );
    }
    return JmSearchPage.fromJson(data);
  }

  Future<JmAlbum> getAlbum(String albumId) async {
    final data = await _getDecodedJson(albumPath, {
      'comicName': '',
      'id': albumId,
    });
    return JmAlbum.fromJson(data);
  }

  Future<JmSearchPage> categoriesFilter({
    int page = 1,
    String time = 'a',
    String category = '0',
    String orderBy = 'mr',
  }) async {
    final order = time == 'a' ? orderBy : '${orderBy}_$time';
    final data = await _getDecodedJson(categoriesFilterPath, {
      'page': page,
      'order': '',
      'c': category,
      'o': order,
    });
    return JmSearchPage.fromJson(data);
  }

  Future<JmSearchPage> ranking(
    String type, {
    int page = 1,
    String category = '0',
  }) {
    final time = switch (type) {
      'daily' => 't',
      'weekly' => 'w',
      'monthly' => 'm',
      _ => throw ArgumentError.value(type, 'type', 'Unsupported ranking type'),
    };
    return categoriesFilter(
      page: page,
      time: time,
      category: category,
      orderBy: 'mv',
    );
  }

  Future<JmChapter> getChapter(String chapterId) async {
    final data = await _getDecodedJson(chapterPath, {
      'comicName': '',
      'skip': '',
      'id': chapterId,
    });
    return JmChapter.fromJson(data);
  }

  Future<JmLoginResult> login(String username, String password) async {
    final data = await _postDecodedJson(loginPath, {
      'username': username,
      'password': password,
    });
    final result = JmLoginResult.fromJson(data);
    if (result.session.isNotEmpty) {
      _cookies['AVS'] = result.session;
    }
    return result;
  }

  Future<JmFavoritePage> getFavoritePage({
    int page = 1,
    String folderId = '0',
    String orderBy = 'mr',
  }) async {
    final data = await _getDecodedJson(favoritePath, {
      'page': page,
      'folder_id': folderId,
      'o': orderBy,
    });
    return JmFavoritePage.fromJson(data);
  }

  Future<Map<String, dynamic>> toggleFavorite(String albumId) {
    return _postDecodedJson(favoritePath, {'aid': albumId});
  }

  String coverUrl(String albumId, {String size = ''}) {
    return _buildImageUrl('/media/albums/$albumId$size.jpg');
  }

  String imageUrl(String photoId, String imageName, {int? scrambleId}) {
    return _buildImageUrl(
      '/media/photos/$photoId/$imageName',
      queryParameters: {'scramble_id': ?scrambleId},
    );
  }

  Future<String> getScramblePage(String chapterId) async {
    await ensureDomainsUpdated();
    final timestamp = timestampProvider();
    final options = Options(
      headers: headersFor(chapterViewTemplatePath, timestamp),
    );

    while (true) {
      final uri = uriFor(
        chapterViewTemplatePath,
        queryParameters: {
          'id': chapterId,
          'mode': 'vertical',
          'page': '0',
          'app_img_shunt': 'NaN',
        },
      );
      try {
        final response = await dio.getUri<String>(uri, options: options);
        return response.data ?? '';
      } on DioException catch (e) {
        if (_shouldRetryRequest(e) && _canSwitchApiDomain()) {
          globalLogger.w(
            'JM domain failover: ${_apiDomains[_apiDomainIndex]} failed '
            '(${e.response?.statusCode ?? e.type}), trying ${_apiDomains[_apiDomainIndex + 1]}',
          );
          _switchApiDomain();
          continue;
        }
        rethrow;
      }
    }
  }

  Future<int> getScrambleId(String chapterId) async {
    final cached = _scrambleIdFutures[chapterId];
    if (cached != null) return cached;

    final future = _fetchScrambleId(chapterId);
    _scrambleIdFutures[chapterId] = future;
    try {
      return await future;
    } catch (_) {
      _scrambleIdFutures.remove(chapterId);
      rethrow;
    }
  }

  Future<int> _fetchScrambleId(String chapterId) async {
    final page = await getScramblePage(chapterId);
    final match = RegExp(r'var scramble_id = (\d+)').firstMatch(page);
    return int.tryParse(match?.group(1) ?? '') ?? JmConstants.scramble220980;
  }

  Future<Map<String, dynamic>> _getDecodedJson(
    String path,
    Map<String, Object?> queryParameters,
  ) {
    return _requestDecodedJson(
      path,
      method: 'GET',
      queryParameters: queryParameters,
    );
  }

  Future<Map<String, dynamic>> _postDecodedJson(
    String path,
    Map<String, Object?> data,
  ) {
    return _requestDecodedJson(path, method: 'POST', data: data);
  }

  Future<Map<String, dynamic>> _requestDecodedJson(
    String path, {
    required String method,
    Map<String, Object?> queryParameters = const {},
    Map<String, Object?>? data,
  }) async {
    await ensureDomainsUpdated();
    var attempts = 0;
    const maxAttempts = 5;

    while (attempts < maxAttempts) {
      attempts++;
      final timestamp = timestampProvider();
      final uri = uriFor(path, queryParameters: queryParameters);
      final options = Options(headers: headersFor(path, timestamp));
      try {
        late final Response<dynamic> response;
        if (method == 'POST') {
          response = await dio.postUri<dynamic>(
            uri,
            data: data,
            options: options.copyWith(
              contentType: Headers.formUrlEncodedContentType,
            ),
          );
        } else {
          response = await dio.getUri<dynamic>(uri, options: options);
        }
        _captureCookies(response);
        final envelope = _responseAsMap(response.data);
        final code = _asInt(envelope['code']);
        if (code != 200) {
          final message =
              (envelope['errorMsg'] ?? envelope['message'] ?? 'JM API error')
                  .toString();
          globalLogger.w('JM API business error: code=$code message=$message');
          throw JmApiException(code: code, message: message);
        }
        final encodedData = envelope['data'];
        if (encodedData is! String) {
          throw FormatException('JM API response is missing encrypted data');
        }
        final decoded = JmCrypto.decodeResponseData(encodedData, timestamp);
        return jsonDecode(decoded) as Map<String, dynamic>;
      } on DioException catch (e) {
        if (!_shouldRetryRequest(e) || attempts >= maxAttempts) {
          rethrow;
        }
        _advanceDomainOrReset();
        globalLogger.w(
          'JM request retry $attempts/$maxAttempts: '
          '${_apiDomains[_apiDomainIndex]} failed '
          '(${e.response?.statusCode ?? e.type})',
        );
      } on FormatException catch (e) {
        if (attempts >= maxAttempts) {
          globalLogger.e(
            'JM API response is not valid JSON after $maxAttempts attempts: ${e.message}',
          );
          throw JmApiException(
            code: 502,
            message: 'JM API returned an invalid response, please retry later',
          );
        }
        _advanceDomainOrReset();
        globalLogger.w(
          'JM request retry $attempts/$maxAttempts: '
          '${_apiDomains[_apiDomainIndex]} returned invalid response (${e.message})',
        );
      }
    }

    throw JmApiException(
      code: 502,
      message: 'JM API request failed after $maxAttempts attempts',
    );
  }

  static bool _shouldRetryRequest(DioException e) {
    final status = e.response?.statusCode;
    if (status != null) {
      if (status == 404 || status == 403 || status >= 500) return true;
    }
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        (e.type == DioExceptionType.unknown && e.error is FormatException);
  }

  void _advanceDomainOrReset() {
    // 域名列表已按“自定义优先、官方兜底”合并，失败时按顺序切换。
    if (_canSwitchApiDomain()) {
      _apiDomainIndex++;
    } else {
      _apiDomainIndex = 0;
    }
  }

  void _captureCookies(Response<dynamic> response) {
    final values = response.headers[_setCookieHeader] ?? const [];
    for (final value in values) {
      final cookie = value.split(';').first;
      final separator = cookie.indexOf('=');
      if (separator <= 0) continue;
      _cookies[cookie.substring(0, separator)] = cookie.substring(
        separator + 1,
      );
    }
  }

  static Map<String, dynamic> _responseAsMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is String) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    throw FormatException(
      'Unsupported JM API response type: ${data.runtimeType}',
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class JmApiException implements Exception {
  final int code;
  final String message;

  const JmApiException({required this.code, required this.message});

  bool get isLoginRequired {
    return code == 401 ||
        message.contains('請先登入會員') ||
        message.contains('请先登入会员') ||
        message.toLowerCase().contains('please login');
  }

  @override
  String toString() => 'JmApiException($code): $message';
}

/// 域名更新失败时抛出，便于上层区分是网络问题还是 JM API 业务错误。
class JmDomainUpdateException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  const JmDomainUpdateException(this.message, [this.stackTrace]);

  @override
  String toString() => 'JmDomainUpdateException: $message';
}

/// JM 直连请求的日志拦截器。
///
/// 把请求/响应/异常写入 [globalLogger]，方便在设置页的统一日志里排查。
class _JmLoggingInterceptor extends Interceptor {
  static const _startKey = 'jm_req_start_ms';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now().millisecondsSinceEpoch;
    final tokenparam =
        options.headers['tokenparam'] ?? options.headers['Tokenparam'];
    globalLogger.d(
      'JM REQ ${options.method} ${options.uri} (tokenparam=$tokenparam)',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final req = response.requestOptions;
    final elapsed = _elapsedMs(req);
    final srvTs = response.headers.value('X-JM-Timestamp');
    if (kReleaseMode) {
      globalLogger.d(
        'JM RES ${req.method} ${req.uri} -> ${response.statusCode} (${elapsed}ms, srv_ts=$srvTs)',
      );
    } else {
      final body = _formatResponseBody(response.data);
      globalLogger.d(
        'JM RES ${req.method} ${req.uri} -> ${response.statusCode} (${elapsed}ms, srv_ts=$srvTs)\n'
        'BODY: $body',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final req = err.requestOptions;
    final status = err.response?.statusCode;
    final elapsed = _elapsedMs(req);
    if (kReleaseMode) {
      globalLogger.e(
        'JM ERR ${req.method} ${req.uri} -> ${status ?? err.type} (${elapsed}ms)',
        error: err.message,
      );
    } else {
      final body = _formatResponseBody(err.response?.data);
      globalLogger.e(
        'JM ERR ${req.method} ${req.uri} -> ${status ?? err.type} (${elapsed}ms)\n'
        'BODY: $body',
        error: err.message,
        stackTrace: err.stackTrace,
      );
    }
    handler.next(err);
  }

  String _formatResponseBody(dynamic data) {
    if (data == null) return '<empty>';
    if (data is Map || data is List) {
      try {
        return const JsonEncoder.withIndent('  ').convert(data);
      } catch (_) {
        return data.toString();
      }
    }
    return data.toString();
  }

  int _elapsedMs(RequestOptions options) {
    final start = options.extra[_startKey] as int?;
    if (start == null) return -1;
    return DateTime.now().millisecondsSinceEpoch - start;
  }
}
