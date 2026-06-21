import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/l10n/app_localizations_en.dart';
import 'package:jm_manga/providers/config_provider.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('ConfigNotifier', () {
    test('normalizes URL with scheme', () {
      expect(
        ConfigNotifier.normalizeBaseUrl('  http://10.0.2.2:8000/  '),
        'http://10.0.2.2:8000',
      );
    });

    test('adds http scheme when missing', () {
      expect(
        ConfigNotifier.normalizeBaseUrl('10.0.2.2:8000'),
        'http://10.0.2.2:8000',
      );
    });

    test('returns default for empty input', () {
      expect(ConfigNotifier.normalizeBaseUrl(''), 'http://127.0.0.1:8000');
    });

    test('accepts loopback addresses', () {
      expect(ConfigNotifier.validateBaseUrl('127.0.0.1:8000', l10n), isNull);
      expect(ConfigNotifier.validateBaseUrl('localhost:8000', l10n), isNull);
    });

    test('accepts emulator and LAN addresses', () {
      expect(ConfigNotifier.validateBaseUrl('10.0.2.2:8000', l10n), isNull);
      expect(ConfigNotifier.validateBaseUrl('192.168.1.5:8000', l10n), isNull);
    });

    test('rejects malformed URL', () {
      expect(ConfigNotifier.validateBaseUrl('127，0.0.1:8000', l10n), isNotNull);
    });
  });
}
