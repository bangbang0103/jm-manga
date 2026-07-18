import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../utils/app_logger.dart';
import 'jm_client.dart';

/// 让图片下载 Dio 共享 JM 登录/年龄验证 Cookie。
class JmImageCookieInterceptor extends Interceptor {
  final JmClient client;

  JmImageCookieInterceptor(this.client);

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

class JmImageLoggingInterceptor extends Interceptor {
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
