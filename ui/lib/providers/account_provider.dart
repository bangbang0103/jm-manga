import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/jm_account.dart';
import '../utils/secure_storage.dart';

final accountListProvider =
    StateNotifierProvider<AccountNotifier, List<JmAccount>>((ref) {
      return AccountNotifier();
    });

final currentAccountIdProvider =
    StateNotifierProvider<CurrentAccountIdNotifier, String?>((ref) {
      return CurrentAccountIdNotifier();
    });

final selectedAccountProvider = Provider<JmAccount?>((ref) {
  final accounts = ref.watch(accountListProvider);
  final id = ref.watch(currentAccountIdProvider);
  if (id == null) return null;
  try {
    return accounts.firstWhere((a) => a.id == id);
  } on StateError {
    return null;
  }
});

class AccountNotifier extends StateNotifier<List<JmAccount>> {
  static const _key = 'jm_accounts';

  AccountNotifier() : super([]) {
    _load();
  }

  static String _passwordKey(String id) => 'jm_account_password_$id';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json != null) {
      try {
        final list = jsonDecode(json) as List<dynamic>;
        final accounts = <JmAccount>[];
        for (final item in list) {
          final account = JmAccount.fromJson(item as Map<String, dynamic>);
          final password = await SecureStorage.read(_passwordKey(account.id));
          accounts.add(account.copyWith(password: password));
        }
        state = accounts;
        return;
      } catch (_) {
        state = [];
      }
    }
  }

  Future<void> _save(List<JmAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    // 敏感字段单独加密存储，JSON 中只保留非敏感字段
    for (final account in accounts) {
      await SecureStorage.write(_passwordKey(account.id), account.password);
    }
    await prefs.setString(
      _key,
      jsonEncode(accounts.map((a) => a.toPublicJson()).toList()),
    );
  }

  Future<void> addAccount(JmAccount account) async {
    if (state.any(
      (a) =>
          !a.isAnonymous &&
          !account.isAnonymous &&
          a.username == account.username,
    )) {
      throw Exception('Account already exists');
    }
    final updated = [...state, account];
    await _save(updated);
    state = updated;
  }

  Future<void> removeAccount(String id) async {
    final updated = state.where((a) => a.id != id).toList();
    await SecureStorage.delete(_passwordKey(id));
    await _save(updated);
    state = updated;
  }

  Future<void> updateAccount(JmAccount account) async {
    final updated = state.map((a) => a.id == account.id ? account : a).toList();
    await _save(updated);
    state = updated;
  }
}

class CurrentAccountIdNotifier extends StateNotifier<String?> {
  static const _key = 'current_jm_account_id';

  CurrentAccountIdNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key);
  }

  Future<void> select(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, id);
    }
    state = id;
  }
}
