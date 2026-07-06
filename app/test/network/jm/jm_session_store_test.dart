import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/network/jm/jm_session_store.dart';

void main() {
  group('JmSessionStore', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('readCookies returns empty map when no cookies stored', () async {
      final store = const JmSessionStore();
      final cookies = await store.readCookies('alice');

      expect(cookies, isEmpty);
    });

    test('writeCookies and readCookies round trip', () async {
      final store = const JmSessionStore();
      await store.writeCookies('alice', {'AVS': 'session'});

      final cookies = await store.readCookies('alice');
      expect(cookies, {'AVS': 'session'});
    });

    test('deleteCookies removes stored cookies', () async {
      final store = const JmSessionStore();
      await store.writeCookies('alice', {'AVS': 'session'});
      await store.deleteCookies('alice');

      final cookies = await store.readCookies('alice');
      expect(cookies, isEmpty);
    });

    test('readCookies ignores invalid json', () async {
      FlutterSecureStorage.setMockInitialValues({
        'jm_session_cookies_alice': 'not-json',
      });

      final store = const JmSessionStore();
      final cookies = await store.readCookies('alice');

      expect(cookies, isEmpty);
    });

    test('readCookies ignores non-map json', () async {
      FlutterSecureStorage.setMockInitialValues({
        'jm_session_cookies_alice': '["a"]',
      });

      final store = const JmSessionStore();
      final cookies = await store.readCookies('alice');

      expect(cookies, isEmpty);
    });
  });
}
