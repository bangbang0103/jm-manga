import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/network/jm/jm_domain.dart';
import 'package:jm_manga/network/jm/jm_image_service_io.dart';
import 'package:jm_manga/network/jm/jm_client.dart';

class _MemoryImageCache extends JmImageCache {
  final _store = <String, Uint8List>{};

  @override
  Future<Uint8List?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, Uint8List bytes) async {
    _store[key] = bytes;
  }
}

void main() {
  group('JmImageService domain fallback', () {
    late Dio dio;
    late JmClient client;
    late JmImageService service;

    setUp(() {
      client = JmClient(
        domains: const JmDomainConfig(
          apiDomains: ['api.test'],
          imageDomains: ['cdn-bad.test', 'cdn-good.test'],
        ),
        autoUpdateDomains: false,
      );

      dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final host = options.uri.host;
            final path = options.uri.path;

            // 第一张图：bad 成功，good 失败 => 赛马选出 bad 作为优选域名。
            if (path.contains('/albums/100')) {
              if (host == 'cdn-bad.test') {
                handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <int>[1],
                    statusCode: 200,
                  ),
                );
              } else {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    type: DioExceptionType.connectionError,
                  ),
                );
              }
              return;
            }

            // 第二张图：bad 失败，good 成功 => 触发优选域名失败后的兜底重试。
            if (path.contains('/albums/101')) {
              if (host == 'cdn-bad.test') {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    type: DioExceptionType.connectionError,
                  ),
                );
              } else {
                handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    data: <int>[2],
                    statusCode: 200,
                  ),
                );
              }
              return;
            }

            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
              ),
            );
          },
        ),
      );

      service = JmImageService(
        dio: dio,
        client: client,
        cache: _MemoryImageCache(),
      );
    });

    test('falls back to other image domains when preferred host fails', () async {
      final first = await service.loadDecodedBytes(
        'https://cdn-bad.test/media/albums/100.jpg',
      );
      expect(first, equals(Uint8List.fromList([1])));

      final second = await service.loadDecodedBytes(
        'https://cdn-bad.test/media/albums/101.jpg',
      );
      expect(second, equals(Uint8List.fromList([2])));
    });
  });

  group('JmImageService custom domain', () {
    test('recognizes custom image host and falls back to https auto domains', () async {
      final client = JmClient(
        domains: const JmDomainConfig(
          apiDomains: ['api.test'],
          imageDomains: ['cdn-auto.test'],
        ),
        autoUpdateDomains: false,
        customImageDomains: const ['http://img.local:3000'],
      );

      final requestedUris = <Uri>[];
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedUris.add(options.uri);
            final host = options.uri.host;
            if (host == 'img.local') {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionError,
                ),
              );
              return;
            }
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                data: <int>[1],
                statusCode: 200,
              ),
            );
          },
        ),
      );

      final service = JmImageService(
        dio: dio,
        client: client,
        cache: _MemoryImageCache(),
      );

      await service.loadDecodedBytes(
        'http://img.local:3000/media/albums/200.jpg',
      );

      expect(requestedUris.length, greaterThanOrEqualTo(2));
      final first = requestedUris.first;
      expect(first.scheme, 'http');
      expect(first.host, 'img.local');
      expect(first.port, 3000);

      final fallback = requestedUris.lastWhere(
        (u) => u.host == 'cdn-auto.test',
      );
      expect(fallback.scheme, 'https');
      expect(fallback.port, 443);
    });

    test('uses custom image domain directly when it succeeds', () async {
      final client = JmClient(
        autoUpdateDomains: false,
        customImageDomains: const ['https://img.custom.test'],
      );

      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                data: <int>[1],
                statusCode: 200,
              ),
            );
          },
        ),
      );

      final service = JmImageService(
        dio: dio,
        client: client,
        cache: _MemoryImageCache(),
      );

      final bytes = await service.loadDecodedBytes(
        'https://img.custom.test/media/albums/201.jpg',
      );

      expect(bytes, equals(Uint8List.fromList([1])));
    });
  });
}
