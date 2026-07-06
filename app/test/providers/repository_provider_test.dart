import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/providers/config_provider.dart';
import 'package:jm_manga/providers/repository_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_repository.dart';

void main() {
  group('repository_provider derived providers', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    ProviderContainer createContainer() {
      return ProviderContainer(
        overrides: [
          apiRepositoryProvider.overrideWithValue(FakeApiRepository()),
        ],
      );
    }

    test('proxyUrlProvider returns null by default', () {
      final container = createContainer();
      addTearDown(container.dispose);

      expect(container.read(proxyUrlProvider), isNull);
    });

    test('autoUpdateJmDomainsProvider defaults to true', () {
      final container = createContainer();
      addTearDown(container.dispose);

      expect(container.read(autoUpdateJmDomainsProvider), isTrue);
    });

    test('customApiDomainsProvider defaults to empty', () {
      final container = createContainer();
      addTearDown(container.dispose);

      expect(container.read(customApiDomainsProvider), isEmpty);
    });

    test('customImageDomainsProvider defaults to empty', () {
      final container = createContainer();
      addTearDown(container.dispose);

      expect(container.read(customImageDomainsProvider), isEmpty);
    });

    test('custom domains are read from config', () async {
      SharedPreferences.setMockInitialValues({
        'customApiDomains': '["https://api.example.com"]',
        'customImageDomains': '["https://img.example.com"]',
        'proxyUrl': 'http://proxy.local:8080',
        'autoSelectJmDomain': false,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(configProvider.notifier).load();

      expect(container.read(proxyUrlProvider), 'http://proxy.local:8080');
      expect(container.read(autoUpdateJmDomainsProvider), isFalse);
      expect(container.read(customApiDomainsProvider), [
        'https://api.example.com',
      ]);
      expect(container.read(customImageDomainsProvider), [
        'https://img.example.com',
      ]);
    });
  });
}
