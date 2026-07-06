import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/models/jm_account.dart';
import 'package:jm_manga/providers/account_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AccountNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('loads empty list when no persisted accounts', () async {
      final notifier = AccountNotifier();
      addTearDown(notifier.dispose);

      await Future.delayed(Duration.zero);

      expect(notifier.state, isEmpty);
    });

    test('loads persisted accounts and merges passwords', () async {
      FlutterSecureStorage.setMockInitialValues({
        'jm_account_password_id1': 'secret',
      });
      SharedPreferences.setMockInitialValues({
        'jm_accounts': jsonEncode([
          {'id': 'id1', 'username': 'alice', 'isAnonymous': false},
        ]),
      });

      final notifier = AccountNotifier();
      addTearDown(notifier.dispose);
      await Future.delayed(Duration.zero);

      expect(notifier.state.length, 1);
      expect(notifier.state.first.username, 'alice');
      expect(notifier.state.first.password, 'secret');
    });

    test('adds account and persists public json and password', () async {
      final notifier = AccountNotifier();
      addTearDown(notifier.dispose);
      await Future.delayed(Duration.zero);

      final account = JmAccount(username: 'bob', password: 'pwd');
      await notifier.addAccount(account);

      expect(notifier.state.length, 1);
      expect(notifier.state.first.username, 'bob');
      expect(notifier.state.first.password, 'pwd');

      final prefs = await SharedPreferences.getInstance();
      final stored = jsonDecode(prefs.getString('jm_accounts')!) as List;
      expect(stored.first['username'], 'bob');
      expect(stored.first.containsKey('password'), isFalse);

      const storage = FlutterSecureStorage();
      expect(await storage.read(key: 'jm_account_password_${account.id}'), 'pwd');
    });

    test('throws when adding duplicate username', () async {
      final notifier = AccountNotifier();
      addTearDown(notifier.dispose);
      await Future.delayed(Duration.zero);

      await notifier.addAccount(
        JmAccount(username: 'alice', password: 'a'),
      );

      expect(
        notifier.addAccount(JmAccount(username: 'alice', password: 'b')),
        throwsException,
      );
    });

    test('removes account and clears secrets', () async {
      FlutterSecureStorage.setMockInitialValues({
        'jm_account_password_id1': 'secret',
        'jm_session_cookies_alice': '{}',
      });
      SharedPreferences.setMockInitialValues({
        'jm_accounts': jsonEncode([
          {'id': 'id1', 'username': 'alice', 'isAnonymous': false},
        ]),
      });

      final notifier = AccountNotifier();
      addTearDown(notifier.dispose);
      await Future.delayed(Duration.zero);

      await notifier.removeAccount('id1');

      expect(notifier.state, isEmpty);
      const storage = FlutterSecureStorage();
      expect(await storage.read(key: 'jm_account_password_id1'), isNull);
      expect(await storage.read(key: 'jm_session_cookies_alice'), isNull);
    });
  });

  group('CurrentAccountIdNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('loads null when no persisted id', () async {
      final notifier = CurrentAccountIdNotifier();
      addTearDown(notifier.dispose);
      await Future.delayed(Duration.zero);

      expect(notifier.state, isNull);
    });

    test('select persists id', () async {
      final notifier = CurrentAccountIdNotifier();
      addTearDown(notifier.dispose);

      await notifier.select('id1');

      expect(notifier.state, 'id1');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('current_jm_account_id'), 'id1');
    });

    test('select null removes persisted id', () async {
      SharedPreferences.setMockInitialValues({
        'current_jm_account_id': 'id1',
      });
      final notifier = CurrentAccountIdNotifier();
      addTearDown(notifier.dispose);

      await notifier.select(null);

      expect(notifier.state, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('current_jm_account_id'), isFalse);
    });
  });

  group('selectedAccountProvider', () {
    test('returns null when no current id', () {
      final container = ProviderContainer(
        overrides: [
          accountListProvider.overrideWith((ref) => AccountNotifier()),
          currentAccountIdProvider.overrideWith(
            (ref) => CurrentAccountIdNotifier(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final account = container.read(selectedAccountProvider);
      expect(account, isNull);
    });
  });
}
