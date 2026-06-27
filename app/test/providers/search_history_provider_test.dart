import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/providers/search_history_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SearchHistoryNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('starts empty when no persisted history', () async {
      final notifier = SearchHistoryNotifier();
      await notifier.ready;
      expect(notifier.state, isEmpty);
    });

    test('adds queries to the front', () async {
      final notifier = SearchHistoryNotifier();
      await notifier.ready;

      await notifier.add('first');
      await notifier.add('second');

      expect(notifier.state, ['second', 'first']);
    });

    test('moves duplicate query to the front', () async {
      final notifier = SearchHistoryNotifier();
      await notifier.ready;

      await notifier.add('first');
      await notifier.add('second');
      await notifier.add('first');

      expect(notifier.state, ['first', 'second']);
    });

    test('trims and ignores empty queries', () async {
      final notifier = SearchHistoryNotifier();
      await notifier.ready;

      await notifier.add('  spaced  ');
      await notifier.add('   ');
      await notifier.add('');

      expect(notifier.state, ['spaced']);
    });

    test('removes old entries when exceeding max count', () async {
      final notifier = SearchHistoryNotifier();
      await notifier.ready;

      for (var i = 1; i <= 31; i++) {
        await notifier.add('query_$i');
      }

      expect(notifier.state.length, 30);
      expect(notifier.state.first, 'query_31');
      expect(notifier.state.last, 'query_2');
    });

    test('removes a query', () async {
      final notifier = SearchHistoryNotifier();
      await notifier.ready;

      await notifier.add('keep');
      await notifier.add('remove');
      await notifier.remove('remove');

      expect(notifier.state, ['keep']);
    });

    test('clears all queries', () async {
      final notifier = SearchHistoryNotifier();
      await notifier.ready;

      await notifier.add('one');
      await notifier.add('two');
      await notifier.clear();

      expect(notifier.state, isEmpty);
    });

    test('loads persisted history', () async {
      SharedPreferences.setMockInitialValues({
        'searchHistory': jsonEncode(['old', 'older']),
      });

      final notifier = SearchHistoryNotifier();
      await notifier.ready;

      expect(notifier.state, ['old', 'older']);
    });

    test('persists changes across instances', () async {
      final first = SearchHistoryNotifier();
      await first.ready;
      await first.add('persisted');

      final second = SearchHistoryNotifier();
      await second.ready;

      expect(second.state, ['persisted']);
    });
  });
}
