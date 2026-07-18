import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/data/direct_manga_repository.dart';
import 'package:jm_manga/providers/config_provider.dart';
import 'package:jm_manga/providers/repository_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../fake_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

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

  group('apiRepositoryProvider JmClient lifecycle', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('配置变更重建 repository 时关闭旧 JmClient', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(configProvider.notifier).load();

      final first =
          container.read(apiRepositoryProvider) as DirectMangaRepository;
      expect(first.client.isClosed, isFalse);

      await container
          .read(configProvider.notifier)
          .setProxyUrl('http://127.0.0.1:7890');

      final second =
          container.read(apiRepositoryProvider) as DirectMangaRepository;
      expect(identical(first, second), isFalse);
      expect(first.client.isClosed, isTrue);
      expect(second.client.isClosed, isFalse);
    });

    test('container dispose 时关闭 JmClient', () async {
      final container = ProviderContainer();
      final repo =
          container.read(apiRepositoryProvider) as DirectMangaRepository;
      expect(repo.client.isClosed, isFalse);

      // 等依赖 provider 构造时启动的异步初始化完成，避免 dispose 后补写状态。
      await Future<void>.delayed(Duration.zero);

      container.dispose();
      expect(repo.client.isClosed, isTrue);
    });
  });

  group('apiRepositoryProvider JmImageService lifecycle', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('配置变更重建 repository 时关闭旧 JmImageService', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(configProvider.notifier).load();

      final first =
          container.read(apiRepositoryProvider) as DirectMangaRepository;
      expect(first.imageService.isClosed, isFalse);

      await container
          .read(configProvider.notifier)
          .setProxyUrl('http://127.0.0.1:7890');

      final second =
          container.read(apiRepositoryProvider) as DirectMangaRepository;
      expect(identical(first, second), isFalse);
      expect(first.imageService.isClosed, isTrue);
      expect(second.imageService.isClosed, isFalse);
    });

    test('container dispose 时关闭 JmImageService', () async {
      final container = ProviderContainer();
      final repo =
          container.read(apiRepositoryProvider) as DirectMangaRepository;
      expect(repo.imageService.isClosed, isFalse);

      // 等依赖 provider 构造时启动的异步初始化完成，避免 dispose 后补写状态。
      await Future<void>.delayed(Duration.zero);

      container.dispose();
      expect(repo.imageService.isClosed, isTrue);
    });
  });
}
