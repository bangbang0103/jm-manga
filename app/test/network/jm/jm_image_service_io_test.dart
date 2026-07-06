import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/network/jm/jm_domain.dart';
import 'package:jm_manga/network/jm/jm_image_service_io.dart';
import 'package:jm_manga/network/jm/jm_client.dart';
import 'package:jm_manga/network/jm/jm_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryImageCache extends JmImageCache {
  final _store = <String, Uint8List>{};

  @override
  Future<Uint8List?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, Uint8List bytes) async {
    _store[key] = bytes;
  }
}

class _ScrambleClient extends JmClient {
  int scrambleCalls = 0;

  _ScrambleClient()
    : super(
        domains: const JmDomainConfig(
          apiDomains: ['api.test'],
          imageDomains: ['cdn.test'],
        ),
        autoUpdateDomains: false,
      );

  @override
  Future<int> getScrambleId(String chapterId) async {
    scrambleCalls += 1;
    return JmConstants.scramble220980;
  }
}

const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempRoot = await Directory.systemTemp.createTemp('jm_image_cache_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (call) async {
          if (call.method == 'getTemporaryDirectory') {
            return tempRoot.path;
          }
          return null;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  group('JmImageCache canonical keys', () {
    test(
      'uses the same pending key for photo urls with different scramble ids',
      () {
        final cache = JmImageCache();
        final first = cache.pendingKeyFor(
          'https://cdn.test/media/photos/10/00001.webp?scramble_id=1',
        );
        final second = cache.pendingKeyFor(
          'https://cdn.test/media/photos/10/00001.webp?scramble_id=2',
        );

        expect(first, second);
      },
    );

    test('reads canonical photo bytes across scramble ids', () async {
      final cache = JmImageCache();
      final bytes = Uint8List.fromList([1, 2, 3]);

      await cache.write(
        'https://cdn.test/media/photos/10/00001.webp?scramble_id=1',
        bytes,
      );

      final cached = await cache.read(
        'https://cdn.test/media/photos/10/00001.webp?scramble_id=2',
      );

      expect(cached, equals(bytes));
    });

    test('falls back to legacy full-url key and migrates it', () async {
      final cache = JmImageCache();
      final legacyUrl =
          'https://cdn.test/media/photos/11/00001.webp?scramble_id=1';
      final canonicalUrl = 'https://cdn.test/media/photos/11/00001.webp';
      final bytes = Uint8List.fromList([4, 5, 6]);
      final legacyFile = _legacyDecodedImageFile(tempRoot.path, legacyUrl);
      await legacyFile.parent.create(recursive: true);
      await legacyFile.writeAsBytes(bytes);

      final legacyCached = await cache.read(legacyUrl);
      final canonicalCached = await _readEventually(cache, canonicalUrl);

      expect(legacyCached, equals(bytes));
      expect(canonicalCached, equals(bytes));
    });
  });

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

    test(
      'falls back to other image domains when preferred host fails',
      () async {
        final first = await service.loadDecodedBytes(
          'https://cdn-bad.test/media/albums/100.jpg',
        );
        expect(first, equals(Uint8List.fromList([1])));

        final second = await service.loadDecodedBytes(
          'https://cdn-bad.test/media/albums/101.jpg',
        );
        expect(second, equals(Uint8List.fromList([2])));
      },
    );
  });

  group('JmImageService custom domain', () {
    test(
      'recognizes custom image host and falls back to official domains',
      () async {
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

        final bytes = await service.loadDecodedBytes(
          'http://img.local:3000/media/albums/200.jpg',
        );
        expect(bytes, equals(Uint8List.fromList([1])));

        expect(requestedUris.length, greaterThanOrEqualTo(2));
        // First attempt uses the custom domain with its configured scheme/port.
        expect(requestedUris.first.scheme, 'http');
        expect(requestedUris.first.host, 'img.local');
        expect(requestedUris.first.port, 3000);
        // Fallback uses the official image domain.
        expect(requestedUris.last.host, 'cdn-auto.test');
        expect(requestedUris.last.scheme, 'https');
      },
    );

    test(
      'races multiple custom image domains preserving scheme and port',
      () async {
        final client = JmClient(
          autoUpdateDomains: false,
          customImageDomains: const [
            'http://img1.local:3000',
            'https://img2.local:4000',
          ],
        );

        final requestedUris = <Uri>[];
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requestedUris.add(options.uri);
              final host = options.uri.host;
              if (host == 'img1.local') {
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
                  data: <int>[2],
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
          'http://img1.local:3000/media/albums/202.jpg',
        );
        expect(bytes, equals(Uint8List.fromList([2])));

        // Both custom domains were attempted.
        final hosts = requestedUris.map((u) => u.host).toSet();
        expect(hosts, contains('img1.local'));
        expect(hosts, contains('img2.local'));

        // The winning request used the second custom domain's scheme and port.
        final winner = requestedUris.lastWhere((u) => u.host == 'img2.local');
        expect(winner.scheme, 'https');
        expect(winner.port, 4000);
        expect(winner.path, '/media/albums/202.jpg');
      },
    );

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

  group('JmImageService cache-first photo loading', () {
    test(
      'fetches scramble id only when a no-scramble photo url misses cache',
      () async {
        final client = _ScrambleClient();
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
          'https://cdn.test/media/photos/10/00001.webp',
        );

        expect(bytes, equals(Uint8List.fromList([1])));
        expect(client.scrambleCalls, 1);
      },
    );
  });
}

File _legacyDecodedImageFile(String tempPath, String key) {
  final digest = md5.convert(Uint8List.fromList(key.codeUnits)).toString();
  return File('$tempPath/jm_decoded_images/$digest.jpg');
}

Future<Uint8List?> _readEventually(JmImageCache cache, String key) async {
  for (var i = 0; i < 20; i++) {
    final bytes = await cache.read(key);
    if (bytes != null) return bytes;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  return null;
}
