import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/utils/custom_domain_utils.dart';

void main() {
  group('CustomDomainUtils.parse', () {
    test('returns null for empty input', () {
      final result = CustomDomainUtils.parse('');
      expect(result.uri, isNull);
      expect(result.error, isNull);
    });

    test('returns null for whitespace-only input', () {
      final result = CustomDomainUtils.parse('   ');
      expect(result.uri, isNull);
      expect(result.error, isNull);
    });

    test('prepends https when scheme is missing', () {
      final result = CustomDomainUtils.parse('example.com');
      expect(result.uri, Uri.parse('https://example.com'));
      expect(result.error, isNull);
    });

    test('preserves http scheme', () {
      final result = CustomDomainUtils.parse('http://example.com');
      expect(result.uri, Uri.parse('http://example.com'));
      expect(result.error, isNull);
    });

    test('preserves https scheme', () {
      final result = CustomDomainUtils.parse('https://example.com');
      expect(result.uri, Uri.parse('https://example.com'));
      expect(result.error, isNull);
    });

    test('supports ip and port', () {
      final result = CustomDomainUtils.parse('192.168.1.2:8080');
      expect(result.uri, Uri.parse('https://192.168.1.2:8080'));
      expect(result.error, isNull);
    });

    test('strips trailing slash', () {
      final result = CustomDomainUtils.parse('https://example.com/');
      expect(result.uri, Uri.parse('https://example.com'));
      expect(result.error, isNull);
    });

    test('trims surrounding whitespace', () {
      final result = CustomDomainUtils.parse('  https://example.com  ');
      expect(result.uri, Uri.parse('https://example.com'));
      expect(result.error, isNull);
    });

    test('rejects unsupported scheme', () {
      final result = CustomDomainUtils.parse('ftp://example.com');
      expect(result.uri, isNull);
      expect(result.error, isNotNull);
    });

    test('rejects missing host', () {
      final result = CustomDomainUtils.parse('https://');
      expect(result.uri, isNull);
      expect(result.error, isNotNull);
    });

    test('rejects non-empty path', () {
      final result = CustomDomainUtils.parse('https://example.com/api');
      expect(result.uri, isNull);
      expect(result.error, isNotNull);
    });

    test('rejects query parameters', () {
      final result = CustomDomainUtils.parse('https://example.com?foo=bar');
      expect(result.uri, isNull);
      expect(result.error, isNotNull);
    });

    test('rejects invalid port', () {
      final result = CustomDomainUtils.parse('example.com:abc');
      expect(result.uri, isNull);
      expect(result.error, isNotNull);
    });
  });
}
