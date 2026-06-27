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
}
