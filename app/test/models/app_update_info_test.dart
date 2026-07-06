import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/models/app_update_info.dart';

void main() {
  group('AppUpdateInfo', () {
    test('holds update metadata', () {
      final info = AppUpdateInfo(
        version: 'v0.3.0',
        releaseNotes: 'New features',
        releaseUrl: 'https://example.com/release',
        publishedAt: DateTime(2026, 1, 1),
      );

      expect(info.version, 'v0.3.0');
      expect(info.releaseNotes, 'New features');
      expect(info.releaseUrl, 'https://example.com/release');
      expect(info.publishedAt, DateTime(2026, 1, 1));
    });

    test('toString includes version and url', () {
      final info = AppUpdateInfo(
        version: 'v0.3.0',
        releaseNotes: '',
        releaseUrl: 'https://example.com/release',
      );

      expect(info.toString(), contains('v0.3.0'));
      expect(info.toString(), contains('https://example.com/release'));
    });
  });
}
