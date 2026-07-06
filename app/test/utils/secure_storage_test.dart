import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/utils/secure_storage.dart';

void main() {
  group('SecureStorage', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('write and read round trip', () async {
      await SecureStorage.write('key1', 'value1');
      expect(await SecureStorage.read('key1'), 'value1');
    });

    test('read returns null for missing key', () async {
      expect(await SecureStorage.read('missing'), isNull);
    });

    test('write empty value deletes key', () async {
      await SecureStorage.write('key1', 'value1');
      await SecureStorage.write('key1', '');
      expect(await SecureStorage.read('key1'), isNull);
    });

    test('write null value deletes key', () async {
      await SecureStorage.write('key1', 'value1');
      await SecureStorage.write('key1', null);
      expect(await SecureStorage.read('key1'), isNull);
    });

    test('delete removes key', () async {
      await SecureStorage.write('key1', 'value1');
      await SecureStorage.delete('key1');
      expect(await SecureStorage.read('key1'), isNull);
    });
  });
}
