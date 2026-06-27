import 'package:dio/dio.dart';

/// 非 IO 平台不配置代理。
void configureDioProxy(Dio dio, String? proxyUrl) {}

/// 非 IO 平台无法测试代理连接。
Future<bool> testProxyConnection(
  String? proxyUrl, {
  Duration timeout = const Duration(seconds: 3),
}) async => false;
