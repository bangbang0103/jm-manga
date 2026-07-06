import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:jm_manga/network/jm/jm_client.dart';
import 'package:jm_manga/network/jm/jm_constants.dart';
import 'package:jm_manga/network/jm/jm_domain.dart';
import 'package:test/test.dart';

const _setCookieHeader = 'set-cookie';

void main() {
  group('JmClient', () {
    test('builds API uri with first configured domain', () {
      final client = JmClient(
        domains: const JmDomainConfig(apiDomains: ['example.test']),
      );

      final uri = client.uriFor(
        '/search',
        queryParameters: {'search_query': 'abc', 'page': 2, 'empty': null},
      );

      expect(
        uri.toString(),
        'https://example.test/search?search_query=abc&page=2',
      );
    });

    test('builds standard mobile headers', () {
      final client = JmClient();

      final headers = client.headersFor(JmClient.searchPath, 1700566805);

      expect(headers['token'], 'cce2cb071cd0cf371a2e34fd5ad66fd6');
      expect(headers['tokenparam'], '1700566805,${JmConstants.appVersion}');
      expect(headers['user-agent'], JmConstants.appUserAgent);
    });

    test('uses content token for chapter view template', () {
      final client = JmClient();

      final headers = client.headersFor(
        JmClient.chapterViewTemplatePath,
        1700566805,
      );

      expect(headers['token'], '68afe23a1ff9e7a3f9c0a846bbf87e6f');
    });

    test('memoizes scramble id requests by chapter id', () async {
      final adapter = _ScramblePageAdapter('var scramble_id = 345678;');
      final client = JmClient(
        dio: Dio()..httpClientAdapter = adapter,
        domains: const JmDomainConfig(apiDomains: ['api.example.test']),
        timestampProvider: () => 1700566805,
        autoUpdateDomains: false,
      );

      final concurrent = await Future.wait([
        client.getScrambleId('10'),
        client.getScrambleId('10'),
      ]);
      final repeated = await client.getScrambleId('10');

      expect(concurrent, [345678, 345678]);
      expect(repeated, 345678);
      expect(adapter.requests.length, 1);
    });

    test('builds CDN cover and image urls', () {
      final client = JmClient(
        domains: const JmDomainConfig(imageDomains: ['img.example.test']),
      );

      expect(
        client.coverUrl('123'),
        'https://img.example.test/media/albums/123.jpg',
      );
      expect(
        client.imageUrl('456', '00001.webp'),
        'https://img.example.test/media/photos/456/00001.webp',
      );
    });

    test('rejects unsupported ranking type before network call', () {
      final client = JmClient();

      expect(() => client.ranking('yearly'), throwsA(isA<ArgumentError>()));
    });

    test('logs in with form data and stores response cookies', () async {
      final adapter = RecordingAdapter([
        StubResponse(
          encryptedData: _loginData,
          headers: _setCookie('ipcountry=HK'),
        ),
      ]);
      final client = JmClient(
        dio: Dio()..httpClientAdapter = adapter,
        domains: const JmDomainConfig(apiDomains: ['api.example.test']),
        timestampProvider: () => 1700566805,
        autoUpdateDomains: false,
      );

      final result = await client.login('alice', 'secret');

      expect(result.username, 'alice');
      expect(result.favorites, 2);
      expect(client.cookies['ipcountry'], 'HK');
      expect(client.cookies['AVS'], 'session-token');

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.path, JmClient.loginPath);
      expect(request.contentType, Headers.formUrlEncodedContentType);
      expect(request.data, {'username': 'alice', 'password': 'secret'});
    });

    test('sends cookies to favorite APIs', () async {
      final adapter = RecordingAdapter([
        const StubResponse(encryptedData: _favoriteData),
        const StubResponse(encryptedData: _toggleData),
      ]);
      final client = JmClient(
        dio: Dio()..httpClientAdapter = adapter,
        domains: const JmDomainConfig(apiDomains: ['api.example.test']),
        timestampProvider: () => 1700566805,
        autoUpdateDomains: false,
      )..setCookies({'AVS': 'session-token'});

      final page = await client.getFavoritePage(page: 2, folderId: '7');
      final toggle = await client.toggleFavorite('123');

      expect(page.total, 1);
      expect(page.items.single.id, '123');
      expect(page.items.single.tags, isEmpty);
      expect(toggle['status'], 'ok');

      final listRequest = adapter.requests.first;
      expect(listRequest.method, 'GET');
      expect(listRequest.uri.path, JmClient.favoritePath);
      expect(listRequest.uri.queryParameters['page'], '2');
      expect(listRequest.uri.queryParameters['folder_id'], '7');
      expect(listRequest.headers['Cookie'], 'AVS=session-token');

      final toggleRequest = adapter.requests.last;
      expect(toggleRequest.method, 'POST');
      expect(toggleRequest.uri.path, JmClient.favoritePath);
      expect(toggleRequest.data, {'aid': '123'});
      expect(toggleRequest.headers['Cookie'], 'AVS=session-token');
    });

    test(
      'cycles through custom API domains then falls back to official',
      () async {
        final adapter = _ConditionalApiAdapter(
          failHosts: const {'api.local'},
          successData: _favoriteData,
        );
        final client = JmClient(
          dio: Dio()..httpClientAdapter = adapter,
          domains: const JmDomainConfig(apiDomains: ['fallback.test']),
          customApiDomains: const ['http://api.local:8080'],
          timestampProvider: () => 1700566805,
          autoUpdateDomains: false,
        );

        // Custom domain fails, then fallback succeeds.
        final result = await client.getFavoritePage(page: 1);
        expect(result.items, isNotEmpty);

        expect(adapter.requests.length, 2);
        expect(adapter.requests.first.uri.host, 'api.local');
        expect(adapter.requests.first.uri.port, 8080);
        expect(adapter.requests.last.uri.host, 'fallback.test');
      },
    );
  });
}

const _loginData =
    'QGQ8+3wLRUn6igO1eRr31o/vv0jv/LaNgpWvlAb1KUmu7WUrPBLh1s8Dv2I/xUSH'
    'Wy/Ftu26QF3H/GehbpAByDFCNA6SfnXcRNP48Cmz6TpRWzbGgD/JpMAR4UxqUwW1'
    'GXoWME729wi5knj99/9bIg==';

const _favoriteData =
    'XFYCx5BLXibxu5tMItAuj5vhsOsOVYw9VjJ546snzd9lpvOl+kGwGjDOHxZYBZH'
    'ZS/jJezYGdmgNa3WnVAoTyNquITZ5QWoOOmwowLzi4SYuCspMkkpAyAPJxfq1u0'
    'fFhoVhKsKeOMt+Om45C4MDDr22ySlfhm3war3ImR8Oh2Q=';

const _toggleData = 'BcIZrbr1mbDHRSwqgKuyJIIkcRrCKVpv4Q0kttVjKtY=';

Map<String, List<String>> _setCookie(String value) {
  return {
    _setCookieHeader: ['$value; Path=/; HttpOnly'],
  };
}

class StubResponse {
  final String encryptedData;
  final Map<String, List<String>> headers;

  const StubResponse({required this.encryptedData, this.headers = const {}});
}

class RecordingAdapter implements HttpClientAdapter {
  final List<StubResponse> responses;
  final List<RequestOptions> requests = [];

  RecordingAdapter(this.responses);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response = responses.removeAt(0);
    return ResponseBody.fromString(
      jsonEncode({'code': 200, 'data': response.encryptedData}),
      200,
      headers: response.headers,
    );
  }

  @override
  void close({bool force = false}) {}
}

class _ConditionalApiAdapter implements HttpClientAdapter {
  final Set<String> failHosts;
  final String successData;
  final List<RequestOptions> requests = [];

  _ConditionalApiAdapter({required this.failHosts, required this.successData});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (failHosts.contains(options.uri.host)) {
      return ResponseBody.fromString('', 502, headers: {});
    }
    return ResponseBody.fromString(
      jsonEncode({'code': 200, 'data': successData}),
      200,
      headers: {},
    );
  }

  @override
  void close({bool force = false}) {}
}

class _ScramblePageAdapter implements HttpClientAdapter {
  final String body;
  final List<RequestOptions> requests = [];

  _ScramblePageAdapter(this.body);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(body, 200);
  }

  @override
  void close({bool force = false}) {}
}
