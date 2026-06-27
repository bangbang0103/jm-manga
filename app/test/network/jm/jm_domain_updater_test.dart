import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/network/jm/jm_domain.dart';
import 'package:jm_manga/network/jm/jm_domain_updater.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FailingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'mock network failure',
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _failingDio() {
  final dio = Dio();
  dio.httpClientAdapter = _FailingAdapter();
  return dio;
}

void main() {
  group('JmDomainUpdater', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns fallback domains when cache and network are empty', () async {
      final updater = JmDomainUpdater(dio: _failingDio());
      final domains = await updater.fetchApiDomains();

      expect(domains, isNotEmpty);
      // Fallback comes from JmConstants.apiDomains.
      expect(domains.first, 'www.cdnaspa.club');
    });

    test('returns cached domains when cache is valid', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'jm_updated_api_domains': ['www.cached.example'],
        'jm_domains_updated_at': now,
      });

      final updater = JmDomainUpdater(dio: _failingDio());
      final domains = await updater.fetchApiDomains();

      expect(domains, ['www.cached.example']);
    });

    test('ignores expired cache and falls back to constants', () async {
      final sixHoursAgo = DateTime.now()
          .subtract(const Duration(hours: 7))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'jm_updated_api_domains': ['www.expired.example'],
        'jm_domains_updated_at': sixHoursAgo,
      });

      final updater = JmDomainUpdater(dio: _failingDio());
      final domains = await updater.fetchApiDomains();

      expect(domains, isNotEmpty);
      expect(domains.first, isNot('www.expired.example'));
    });

    test('fetchDomainConfig returns config with fallback domains', () async {
      final updater = JmDomainUpdater(dio: _failingDio());
      final config = await updater.fetchDomainConfig();

      expect(config, isA<JmDomainConfig>());
      expect(config.apiDomains, isNotEmpty);
      expect(config.imageDomains, isNotEmpty);
    });
  });
}
