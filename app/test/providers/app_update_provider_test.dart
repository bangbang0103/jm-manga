import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/models/app_update_info.dart';
import 'package:jm_manga/providers/app_update_provider.dart';
import 'package:jm_manga/services/app_update_service.dart';

class _FakeAppUpdateService extends AppUpdateService {
  final AppUpdateInfo? _info;
  final Exception? _error;

  _FakeAppUpdateService({this._info, this._error}) : super();

  @override
  Future<AppUpdateInfo> fetchLatestRelease() async {
    if (_error != null) throw _error;
    return _info!;
  }
}

void main() {
  group('AppUpdateNotifier', () {
    test('detects update when remote version is newer', () async {
      final service = _FakeAppUpdateService(
        info: const AppUpdateInfo(
          version: 'v0.3.0',
          releaseNotes: 'new',
          releaseUrl: 'https://example.com/v0.3.0',
        ),
      );
      final notifier = AppUpdateNotifier(
        service: service,
        currentVersion: '0.2.1',
      );
      addTearDown(notifier.dispose);

      await notifier.checkForUpdates();

      expect(notifier.state.isChecking, false);
      expect(notifier.state.latestInfo?.version, 'v0.3.0');
      expect(notifier.state.hasUpdate, true);
      expect(notifier.state.error, isNull);
    });

    test('does not detect update when remote version is older or equal', () async {
      final service = _FakeAppUpdateService(
        info: const AppUpdateInfo(
          version: 'v0.2.1',
          releaseNotes: 'same',
          releaseUrl: 'https://example.com/v0.2.1',
        ),
      );
      final notifier = AppUpdateNotifier(
        service: service,
        currentVersion: '0.2.1+1',
      );
      addTearDown(notifier.dispose);

      await notifier.checkForUpdates();

      expect(notifier.state.latestInfo?.version, 'v0.2.1');
      expect(notifier.state.hasUpdate, false);
    });

    test('sets error state when request fails', () async {
      final service = _FakeAppUpdateService(
        error: Exception('network down'),
      );
      final notifier = AppUpdateNotifier(
        service: service,
        currentVersion: '0.2.1',
      );
      addTearDown(notifier.dispose);

      await notifier.checkForUpdates(silent: false);

      expect(notifier.state.isChecking, false);
      expect(notifier.state.latestInfo, isNull);
      expect(notifier.state.error, isNotNull);
    });

    test('silent failures do not set error state', () async {
      final service = _FakeAppUpdateService(
        error: Exception('network down'),
      );
      final notifier = AppUpdateNotifier(
        service: service,
        currentVersion: '0.2.1',
      );
      addTearDown(notifier.dispose);

      await notifier.checkForUpdates(silent: true);

      expect(notifier.state.error, isNull);
    });

    test('setCurrentVersion updates the current version', () {
      final notifier = AppUpdateNotifier(
        service: _FakeAppUpdateService(),
        currentVersion: '',
      );
      addTearDown(notifier.dispose);

      notifier.setCurrentVersion('0.2.1+1');

      expect(notifier.state.currentVersion, '0.2.1+1');
    });
  });
}
