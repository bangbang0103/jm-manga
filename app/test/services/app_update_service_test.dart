import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/services/app_update_service.dart';

void main() {
  group('AppUpdateService', () {
    test('parses latest release response', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'tag_name': 'v0.3.0',
                  'body': '## 0.3.0\n- New feature',
                  'html_url': 'https://github.com/bangbang0103/jm-manga/releases/tag/v0.3.0',
                  'published_at': '2026-06-27T12:00:00Z',
                },
              ),
            );
          },
        ),
      );

      final service = AppUpdateService(dio: dio);
      final info = await service.fetchLatestRelease();

      expect(info.version, 'v0.3.0');
      expect(info.releaseNotes, '## 0.3.0\n- New feature');
      expect(
        info.releaseUrl,
        'https://github.com/bangbang0103/jm-manga/releases/tag/v0.3.0',
      );
      expect(info.publishedAt, DateTime.utc(2026, 6, 27, 12, 0, 0));
    });

    test('throws when response status is not 200', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 404,
                data: {'message': 'Not Found'},
              ),
            );
          },
        ),
      );

      final service = AppUpdateService(dio: dio);
      expect(service.fetchLatestRelease(), throwsException);
    });

    test('throws when tag_name is missing', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'body': 'notes',
                  'html_url': 'https://example.com',
                },
              ),
            );
          },
        ),
      );

      final service = AppUpdateService(dio: dio);
      expect(service.fetchLatestRelease(), throwsException);
    });

    test('uses configured owner and repo in request url', () async {
      late final String capturedUrl;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedUrl = '${options.baseUrl}${options.path}';
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'tag_name': 'v0.3.0',
                  'body': '',
                  'html_url': 'https://example.com',
                },
              ),
            );
          },
        ),
      );

      final service = AppUpdateService(
        dio: dio,
        repoOwner: 'custom-owner',
        repoName: 'custom-repo',
      );
      await service.fetchLatestRelease();

      expect(
        capturedUrl,
        'https://api.github.com/repos/custom-owner/custom-repo/releases/latest',
      );
    });
  });
}
