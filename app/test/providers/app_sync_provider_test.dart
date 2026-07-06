import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/providers/app_sync_provider.dart';

void main() {
  group('lastAccountSwitchSyncProvider', () {
    test('initial state is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(lastAccountSwitchSyncProvider), isNull);
    });

    test('state can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final now = DateTime(2026, 1, 1);
      container.read(lastAccountSwitchSyncProvider.notifier).state = now;

      expect(container.read(lastAccountSwitchSyncProvider), now);
    });
  });
}
