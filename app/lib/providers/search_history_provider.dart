import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 管理本地搜索历史。
///
/// 搜索历史保存在 SharedPreferences 中，全局一份，不区分账号。
/// - 最大保存 30 条；
/// - 精确去重（区分大小写），重复 query 会被移到最前；
/// - 保存时自动 trim，忽略空串。
class SearchHistoryNotifier extends StateNotifier<List<String>> {
  static const _historyKey = 'searchHistory';
  static const _maxCount = 30;

  final Completer<void> _ready = Completer<void>();

  /// 首次从 SharedPreferences 加载完成的 Future。
  /// 测试中可先 await 它，避免 constructor 里异步 load 产生竞态。
  Future<void> get ready => _ready.future;

  SearchHistoryNotifier() : super(const []) {
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) {
      state = const [];
    } else {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        state = decoded.whereType<String>().toList();
      } catch (_) {
        state = const [];
      }
    }
    if (!_ready.isCompleted) {
      _ready.complete();
    }
  }

  Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final updated = [...state];
    updated.remove(trimmed);
    updated.insert(0, trimmed);
    if (updated.length > _maxCount) {
      updated.removeLast();
    }
    state = updated;
    await _persist(updated);
  }

  Future<void> remove(String query) async {
    final updated = state.where((q) => q != query).toList();
    if (updated.length == state.length) return;
    state = updated;
    await _persist(updated);
  }

  Future<void> clear() async {
    state = const [];
    await _persist(const []);
  }

  Future<void> _persist(List<String> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey, jsonEncode(history));
  }
}

final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<String>>((ref) {
      return SearchHistoryNotifier();
    });
