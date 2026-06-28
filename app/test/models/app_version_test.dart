import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/models/app_version.dart';

void main() {
  group('AppVersion.parse', () {
    test('parses version with v prefix', () {
      final version = AppVersion.parse('v0.2.1');
      expect(version.major, 0);
      expect(version.minor, 2);
      expect(version.patch, 1);
    });

    test('parses version without v prefix', () {
      final version = AppVersion.parse('0.2.1');
      expect(version.major, 0);
      expect(version.minor, 2);
      expect(version.patch, 1);
    });

    test('ignores build number after +', () {
      final version = AppVersion.parse('0.2.1+5');
      expect(version.major, 0);
      expect(version.minor, 2);
      expect(version.patch, 1);
    });

    test('throws FormatException for empty string', () {
      expect(() => AppVersion.parse(''), throwsFormatException);
    });

    test('throws FormatException for invalid version', () {
      expect(() => AppVersion.parse('not-a-version'), throwsFormatException);
    });
  });

  group('AppVersion comparison', () {
    test('same version is not newer', () {
      final a = AppVersion.parse('0.2.1');
      final b = AppVersion.parse('v0.2.1');
      expect(a.isNewerThan(b), false);
    });

    test('higher patch is newer', () {
      final a = AppVersion.parse('0.2.2');
      final b = AppVersion.parse('0.2.1');
      expect(a.isNewerThan(b), true);
    });

    test('higher minor is newer', () {
      final a = AppVersion.parse('0.3.0');
      final b = AppVersion.parse('0.2.9');
      expect(a.isNewerThan(b), true);
    });

    test('higher major is newer', () {
      final a = AppVersion.parse('1.0.0');
      final b = AppVersion.parse('0.9.9');
      expect(a.isNewerThan(b), true);
    });

    test('lower version is not newer', () {
      final a = AppVersion.parse('0.2.1');
      final b = AppVersion.parse('0.2.2');
      expect(a.isNewerThan(b), false);
    });

    test('10 is newer than 2 in same position', () {
      final a = AppVersion.parse('0.10.0');
      final b = AppVersion.parse('0.2.0');
      expect(a.isNewerThan(b), true);
    });
  });
}
