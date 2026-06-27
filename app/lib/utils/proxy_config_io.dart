import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

String? _proxyDirective(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  final trimmed = url.trim();
  Uri? uri;
  if (trimmed.contains('://')) {
    uri = Uri.tryParse(trimmed);
  } else {
    uri = Uri.tryParse('http://$trimmed');
  }
  if (uri == null || uri.host.isEmpty) return null;
  final hostPort = '${uri.host}:${uri.port}';
  final scheme = uri.scheme.toLowerCase();
  if (scheme == 'socks5' || scheme == 'socks4' || scheme == 'socks') {
    return 'SOCKS5PROXY $hostPort';
  }
  return 'PROXY $hostPort';
}

({String host, int port})? _parseProxyHostPort(String? url) {
  final trimmed = url?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  Uri? uri;
  if (trimmed.contains('://')) {
    uri = Uri.tryParse(trimmed);
  } else {
    uri = Uri.tryParse('http://$trimmed');
  }
  if (uri == null || uri.host.isEmpty || uri.port <= 0) return null;
  return (host: uri.host, port: uri.port);
}

void configureDioProxy(Dio dio, String? proxyUrl) {
  final directive = _proxyDirective(proxyUrl);
  if (directive == null) return;
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.findProxy = (_) => directive;
      return client;
    },
  );
}

/// 测试能否直接连上代理的 TCP 端口。
/// 返回 true 表示端口可连；false 表示无法连接、DNS 失败或地址无效。
Future<bool> testProxyConnection(
  String? proxyUrl, {
  Duration timeout = const Duration(seconds: 3),
}) async {
  final hostPort = _parseProxyHostPort(proxyUrl);
  if (hostPort == null) return false;
  Socket? socket;
  try {
    socket = await Socket.connect(
      hostPort.host,
      hostPort.port,
      timeout: timeout,
    );
    await socket.close();
    return true;
  } catch (_) {
    return false;
  } finally {
    socket?.destroy();
  }
}
