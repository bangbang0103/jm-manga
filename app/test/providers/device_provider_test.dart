import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/providers/device_provider.dart';

void main() {
  group('DeviceIdNotifier', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('generates new device id when none exists', () async {
      final notifier = DeviceIdNotifier();
      addTearDown(notifier.dispose);
      await Future.delayed(Duration.zero);

      expect(notifier.state, isNotNull);
      expect(notifier.state!.length, greaterThan(10));

      const storage = FlutterSecureStorage();
      expect(await storage.read(key: 'jm_manga_device_id'), notifier.state);
    });

    test('loads existing device id', () async {
      FlutterSecureStorage.setMockInitialValues({
        'jm_manga_device_id': 'existing-id',
      });

      final notifier = DeviceIdNotifier();
      addTearDown(notifier.dispose);
      await Future.delayed(Duration.zero);

      expect(notifier.state, 'existing-id');
    });
  });
}
