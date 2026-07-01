import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/providers/config_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ConfigNotifier custom domains', () {
    test('initial state has empty custom domain lists', () {
      final notifier = ConfigNotifier();
      addTearDown(notifier.dispose);

      expect(notifier.state.customApiDomains, isEmpty);
      expect(notifier.state.customImageDomains, isEmpty);
    });

    test('loads custom domain lists from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'customApiDomains': jsonEncode(['https://api.example.com']),
        'customImageDomains': jsonEncode(['http://192.168.1.2:8080']),
      });
      final notifier = ConfigNotifier();
      addTearDown(notifier.dispose);
      await notifier.load();

      expect(
        notifier.state.customApiDomains,
        ['https://api.example.com'],
      );
      expect(
        notifier.state.customImageDomains,
        ['http://192.168.1.2:8080'],
      );
    });

    test('setCustomApiDomains persists JSON list', () async {
      final notifier = ConfigNotifier();
      addTearDown(notifier.dispose);

      await notifier.setCustomApiDomains([
        'https://api.example.com',
        'api2.example.com',
      ]);

      expect(
        notifier.state.customApiDomains,
        ['https://api.example.com', 'https://api2.example.com'],
      );
      final prefs = await SharedPreferences.getInstance();
      final stored = jsonDecode(prefs.getString('customApiDomains')!) as List;
      expect(stored, ['https://api.example.com', 'https://api2.example.com']);
    });

    test('setCustomImageDomains persists JSON list', () async {
      final notifier = ConfigNotifier();
      addTearDown(notifier.dispose);

      await notifier.setCustomImageDomains([
        'http://img.local:3000',
        'img2.local',
      ]);

      expect(
        notifier.state.customImageDomains,
        ['http://img.local:3000', 'https://img2.local'],
      );
      final prefs = await SharedPreferences.getInstance();
      final stored = jsonDecode(
        prefs.getString('customImageDomains')!,
      ) as List;
      expect(stored, ['http://img.local:3000', 'https://img2.local']);
    });

    test('empty list clears custom domains', () async {
      SharedPreferences.setMockInitialValues({
        'customApiDomains': jsonEncode(['https://api.example.com']),
      });
      final notifier = ConfigNotifier();
      addTearDown(notifier.dispose);
      await notifier.load();

      await notifier.setCustomApiDomains(const <String>[]);

      expect(notifier.state.customApiDomains, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('customApiDomains'), false);
    });

    test('invalid raw values are ignored during load', () async {
      SharedPreferences.setMockInitialValues({
        'customApiDomains': 'not-json',
      });
      final notifier = ConfigNotifier();
      addTearDown(notifier.dispose);
      await notifier.load();

      expect(notifier.state.customApiDomains, isEmpty);
    });
  });

  group('ConfigNotifier excluded tags', () {
    test('initial state has empty excluded tags', () {
      final notifier = ConfigNotifier();
      addTearDown(notifier.dispose);

      expect(notifier.state.excludedTags, isEmpty);
    });

    test('loads excluded tags from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'excludedTags': jsonEncode(['全彩', '人妻']),
      });
      final notifier = ConfigNotifier();
      addTearDown(notifier.dispose);
      await notifier.load();

      expect(notifier.state.excludedTags, ['全彩', '人妻']);
    });

    test('setExcludedTags persists JSON list and deduplicates', () async {
      final notifier = ConfigNotifier();
      addTearDown(notifier.dispose);

      await notifier.setExcludedTags(['全彩', '  全彩  ', 'AI生成']);

      expect(notifier.state.excludedTags, ['全彩', 'ai生成']);
      final prefs = await SharedPreferences.getInstance();
      final stored = jsonDecode(prefs.getString('excludedTags')!) as List;
      expect(stored, ['全彩', 'ai生成']);
    });

    test('empty list clears excluded tags', () async {
      SharedPreferences.setMockInitialValues({
        'excludedTags': jsonEncode(['全彩']),
      });
      final notifier = ConfigNotifier();
      addTearDown(notifier.dispose);
      await notifier.load();

      await notifier.setExcludedTags(const <String>[]);

      expect(notifier.state.excludedTags, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('excludedTags'), false);
    });

    test('invalid raw values are ignored during load', () async {
      SharedPreferences.setMockInitialValues({
        'excludedTags': 'not-json',
      });
      final notifier = ConfigNotifier();
      addTearDown(notifier.dispose);
      await notifier.load();

      expect(notifier.state.excludedTags, isEmpty);
    });
  });
}
