import 'dart:async';

import 'package:dio/dio.dart';

import '../utils/app_logger.dart';
import 'api_client_platform.dart';

class ApiClient {
  final Dio dio;
  final String? apiToken;
  final String? jmUsername;
  final String? deviceId;

  ApiClient({
    required String baseUrl,
    this.apiToken,
    this.jmUsername,
    this.deviceId,
    Dio? dioInstance,
    this.onUnauthorized,
  }) : dio =
           dioInstance ??
           _createDio(baseUrl, apiToken, jmUsername, deviceId, onUnauthorized);

  /// 401 统一处理回调，由调用方注入（如清除本地 token 并跳转登录）。
  final FutureOr<void> Function()? onUnauthorized;

  static Dio _createDio(
    String baseUrl,
    String? apiToken,
    String? jmUsername,
    String? deviceId,
    FutureOr<void> Function()? onUnauthorized,
  ) {
    final headers = <String, String>{};
    if (apiToken != null && apiToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiToken';
    }
    if (jmUsername != null && jmUsername.isNotEmpty) {
      headers['X-JM-Username'] = jmUsername;
    }
    if (deviceId != null && deviceId.isNotEmpty) {
      headers['X-Device-Id'] = deviceId;
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 60),
        headers: headers.isEmpty ? null : headers,
      ),
    );

    dio.interceptors.add(_AuthInterceptor(onUnauthorized: onUnauthorized));
    dio.interceptors.add(_RetryInterceptor(dio));
    dio.interceptors.add(_LoggingInterceptor());

    configurePlatformHttpClient(dio);

    return dio;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await dio.get<T>(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  factory ApiException.fromDio(DioException e) {
    final response = e.response;
    if (response != null) {
      final data = response.data;
      String message;
      if (data is Map<String, dynamic>) {
        message = data['message'] as String? ?? e.message ?? 'Request failed';
      } else if (data is String) {
        message = data.isNotEmpty ? data : (e.message ?? 'Request failed');
      } else {
        message = e.message ?? 'Request failed';
      }
      return ApiException(message, statusCode: response.statusCode);
    }
    return ApiException(e.message ?? 'Network error');
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// 401 统一拦截器。
///
/// 收到 401 时先触发 [onUnauthorized] 回调，由调用方清理本地凭据；
/// 随后仍抛出 ApiException，便于 UI 展示登录提示。
class _AuthInterceptor extends Interceptor {
  final FutureOr<void> Function()? onUnauthorized;

  _AuthInterceptor({this.onUnauthorized});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      try {
        onUnauthorized?.call();
      } catch (_) {
        // 回调失败不应阻止后续错误处理。
      }
    }
    handler.next(err);
  }
}

/// 重试拦截器。
///
/// 对幂等的 GET 请求在连接/接收超时、连接错误或服务端 5xx 时自动重试，
/// 最多 2 次，间隔指数退避（500ms / 1s）。非幂等请求（POST/PUT/DELETE）不重试。
class _RetryInterceptor extends Interceptor {
  static const _maxRetries = 2;
  static const _baseDelayMs = 500;

  final Dio _dio;

  _RetryInterceptor(this._dio);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.requestOptions;
    if (requestOptions.method != 'GET') {
      handler.next(err);
      return;
    }

    final retryCount = (requestOptions.extra['_retryCount'] as int?) ?? 0;
    if (retryCount >= _maxRetries) {
      handler.next(err);
      return;
    }

    final shouldRetry = _shouldRetry(err);
    if (!shouldRetry) {
      handler.next(err);
      return;
    }

    await Future.delayed(
      Duration(milliseconds: _baseDelayMs * (1 << retryCount)),
    );

    try {
      requestOptions.extra['_retryCount'] = retryCount + 1;
      final response = await _dio.fetch(requestOptions);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  bool _shouldRetry(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }
    final statusCode = err.response?.statusCode;
    return statusCode != null && statusCode >= 500 && statusCode < 600;
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    globalLogger.d('${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    globalLogger.d(
      '${response.requestOptions.method} ${response.requestOptions.path} -> ${response.statusCode}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    globalLogger.e(
      '${err.requestOptions.method} ${err.requestOptions.path} -> ${err.response?.statusCode ?? err.type}',
      error: err.message,
      stackTrace: err.stackTrace,
    );
    handler.next(err);
  }
}
