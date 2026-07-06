import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/models/jm_account.dart';
import 'package:jm_manga/providers/account_provider.dart';
import 'package:jm_manga/providers/device_provider.dart';
import 'package:jm_manga/providers/owner_key_provider.dart';

void main() {
  group('ownerKeyProvider', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    ProviderContainer createContainer({
      required JmAccount? account,
      required String deviceId,
    }) {
      return ProviderContainer(
        overrides: [
          selectedAccountProvider.overrideWithValue(account),
          deviceIdProvider.overrideWith((ref) {
            final notifier = DeviceIdNotifier();
            notifier.state = deviceId;
            return notifier;
          }),
        ],
      );
    }

    test('returns jm prefix when account is selected', () {
      final container = createContainer(
        account: JmAccount(id: 'a', username: 'alice'),
        deviceId: 'device-123',
      );
      addTearDown(container.dispose);

      expect(container.read(ownerKeyProvider), 'jm:alice');
    });

    test('returns device prefix when account is anonymous', () {
      final container = createContainer(
        account: JmAccount(id: 'a', isAnonymous: true),
        deviceId: 'device-123',
      );
      addTearDown(container.dispose);

      expect(container.read(ownerKeyProvider), 'device:device-123');
    });

    test('returns device prefix when no account selected', () {
      final container = createContainer(
        account: null,
        deviceId: 'device-123',
      );
      addTearDown(container.dispose);

      expect(container.read(ownerKeyProvider), 'device:device-123');
    });

    test('falls back to pending when device id is empty', () {
      final container = createContainer(account: null, deviceId: '');
      addTearDown(container.dispose);

      expect(container.read(ownerKeyProvider), 'device:pending');
    });
  });
}
