import 'package:jm_manga/network/jm/jm_client.dart';
import 'package:jm_manga/network/jm/jm_domain.dart';
import 'package:jm_manga/network/jm/jm_domain_updater.dart';
import 'package:test/test.dart';

class _FakeDomainUpdater extends JmDomainUpdater {
  final JmDomainConfig _config;

  _FakeDomainUpdater(this._config) : super(dio: null);

  @override
  Future<JmDomainConfig> fetchDomainConfig() async => _config;
}

void main() {
  group('JmClient custom domains', () {
    test('uses custom API domains first and keeps official fallback', () {
      final client = JmClient(
        autoUpdateDomains: false,
        customApiDomains: const ['https://api.custom.test'],
      );

      expect(client.apiDomains.first, 'api.custom.test');
      expect(client.apiDomains.length, greaterThan(1));

      final uri = client.uriFor('/search', queryParameters: {'page': 1});
      expect(uri.scheme, 'https');
      expect(uri.host, 'api.custom.test');
      expect(uri.path, '/search');
    });

    test('uses http scheme when first custom API domain specifies it', () {
      final client = JmClient(
        autoUpdateDomains: false,
        customApiDomains: const ['http://api.local:8080'],
      );

      final uri = client.uriFor('/search');
      expect(uri.scheme, 'http');
      expect(uri.host, 'api.local');
      expect(uri.port, 8080);
    });

    test('keeps custom API domains first and official fallback after switching', () {
      final client = JmClient(
        autoUpdateDomains: false,
        domains: const JmDomainConfig(apiDomains: ['fallback.test']),
        customApiDomains: const ['https://api.custom.test'],
      );

      expect(client.apiDomains, ['api.custom.test', 'fallback.test']);
      client.selectApiDomain(0);

      final uri = client.uriFor('/search');
      expect(uri.host, 'api.custom.test');
      expect(uri.scheme, 'https');
    });

    test('multiple custom API domains are tried in order', () {
      final client = JmClient(
        autoUpdateDomains: false,
        customApiDomains: const [
          'https://api.first.test',
          'https://api.second.test',
        ],
      );

      expect(client.apiDomains.take(2), [
        'api.first.test',
        'api.second.test',
      ]);

      client.selectApiDomain(1);
      final uri = client.uriFor('/search');
      expect(uri.host, 'api.second.test');
    });

    test('prepends custom image domain and uses it for image URLs', () {
      final client = JmClient(
        autoUpdateDomains: false,
        customImageDomains: const ['https://img.custom.test'],
      );

      expect(client.imageDomains.first, 'img.custom.test');

      final url = client.coverUrl('123');
      expect(url, 'https://img.custom.test/media/albums/123.jpg');
    });

    test('custom image domain with port and scramble query', () {
      final client = JmClient(
        autoUpdateDomains: false,
        customImageDomains: const ['http://img.local:3000'],
      );

      final url = client.imageUrl('456', '00001.webp', scrambleId: 99);
      final uri = Uri.parse(url);
      expect(uri.scheme, 'http');
      expect(uri.host, 'img.local');
      expect(uri.port, 3000);
      expect(uri.path, '/media/photos/456/00001.webp');
      expect(uri.queryParameters['scramble_id'], '99');
    });

    test('multiple custom image domains are tried in order', () {
      final client = JmClient(
        autoUpdateDomains: false,
        customImageDomains: const [
          'https://img.first.test',
          'https://img.second.test',
        ],
      );

      expect(client.imageDomains.take(2), [
        'img.first.test',
        'img.second.test',
      ]);
    });

    test('domain updater prepends custom domains and appends updated official domains', () async {
      final client = JmClient(
        autoUpdateDomains: true,
        customApiDomains: const ['https://api.custom.test'],
        customImageDomains: const ['https://img.custom.test'],
        domainUpdater: _FakeDomainUpdater(
          const JmDomainConfig(
            apiDomains: ['updated.api.test'],
            imageDomains: ['updated.img.test'],
          ),
        ),
      );

      await client.ensureDomainsUpdated();

      expect(client.apiDomains, ['api.custom.test', 'updated.api.test']);
      expect(client.imageDomains, ['img.custom.test', 'updated.img.test']);
    });
  });
}
