import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/data/api_client.dart';

void main() {
  group('ApiClient', () {
    test('uses provided base url and token', () {
      final client = ApiClient(
        baseUrl: 'https://example.com',
        apiToken: 'token123',
        deviceId: 'device123',
      );

      expect(client.dio.options.baseUrl, 'https://example.com');
      expect(client.dio.options.headers['Authorization'], 'Bearer token123');
      expect(client.dio.options.headers['X-Device-Id'], 'device123');
    });

    test('does not set auth header when token is empty', () {
      final client = ApiClient(baseUrl: 'https://example.com');

      expect(client.dio.options.headers.containsKey('Authorization'), isFalse);
    });
  });
}
