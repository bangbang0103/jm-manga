import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/data/api_client.dart';
import 'package:jm_manga/data/api_repository.dart';

class FakeApiClient extends ApiClient {
  String? lastPath;
  Map<String, dynamic>? lastQuery;
  final List<String> paths = [];

  FakeApiClient() : super(baseUrl: 'http://test.com');

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    lastPath = path;
    lastQuery = queryParameters;
    paths.add(path);
    if (path == '/health') {
      return Response<T>(
        data:
            {'status': 'ok', 'version': '0.1.0-test', 'uptime_seconds': 1} as T,
        statusCode: 200,
        requestOptions: RequestOptions(),
      );
    }
    if (path == '/api/v1/server/cache') {
      return Response<T>(
        data: {'covers': 10, 'images': 20, 'database': 30} as T,
        statusCode: 200,
        requestOptions: RequestOptions(),
      );
    }
    return Response<T>(
      data:
          {
                'code': 'OK',
                'data': {
                  'items': [
                    {
                      'album_id': '1',
                      'title': 'A',
                      'tags': ['x'],
                    },
                  ],
                  'total': 1,
                },
              }
              as T,
      statusCode: 200,
      requestOptions: RequestOptions(),
    );
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    lastPath = path;
    lastQuery = queryParameters;
    paths.add(path);
    return Response<T>(
      data:
          {
                'code': 'OK',
                'message': 'success',
                'data': {'synced': true, 'count': 2, 'page': 1},
              }
              as T,
      statusCode: 200,
      requestOptions: RequestOptions(),
    );
  }
}

void main() {
  group('ApiRepository', () {
    test('search parses album items', () async {
      final fakeClient = FakeApiClient();

      final repo = ApiRepository(client: fakeClient);

      final results = await repo.search('test');
      expect(results.length, 1);
      expect(results.first.albumId, '1');
      expect(results.first.title, 'A');
      expect(fakeClient.lastPath, '/api/v1/search');
      expect(fakeClient.lastQuery?['q'], 'test');
    });

    test('coverUrl builds url', () {
      final client = ApiClient(baseUrl: 'http://test.com');
      final repo = ApiRepository(client: client);

      final url = repo.coverUrl('album1');
      expect(url, 'http://test.com/api/v1/covers/album1?size=_3x4');
    });

    test('imageHeaders injects token and username', () {
      final client = ApiClient(
        baseUrl: 'http://test.com',
        apiToken: 'secret',
        jmUsername: 'user',
      );
      final repo = ApiRepository(client: client);

      expect(repo.imageHeaders['Authorization'], 'Bearer secret');
      expect(repo.imageHeaders['X-JM-Username'], 'user');
    });

    test('syncFavorites returns ApiResponse data payload', () async {
      final fakeClient = FakeApiClient();
      final repo = ApiRepository(client: fakeClient);

      final result = await repo.syncFavorites(force: true, full: true);

      expect(result['synced'], isTrue);
      expect(result['count'], 2);
      expect(fakeClient.lastPath, '/api/v1/favorites/sync');
    });

    test('getServerCacheSizes parses database size', () async {
      final fakeClient = FakeApiClient();
      final repo = ApiRepository(client: fakeClient);

      final sizes = await repo.getServerCacheSizes();

      expect(sizes, {'covers': 10, 'images': 20, 'database': 30});
    });

    test(
      'validateConnection checks health and authenticated cache endpoint',
      () async {
        final fakeClient = FakeApiClient();
        final repo = ApiRepository(client: fakeClient);

        final result = await repo.validateConnection();

        expect(result['status'], 'ok');
        expect(
          fakeClient.paths,
          containsAll(['/health', '/api/v1/server/cache']),
        );
      },
    );
  });
}
