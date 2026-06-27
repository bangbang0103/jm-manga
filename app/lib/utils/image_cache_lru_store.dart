import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 管理图片缓存的 LRU 元数据。
///
/// 以 url 为 key，最后一次访问时间戳（毫秒）为 value 存到 SharedPreferences。
class ImageCacheLruStore {
  static const _prefsKey = 'jm_image_cache_lru_v1';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<Map<String, int>> readAll() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final entry in decoded.entries)
          if (entry.value is int) entry.key: entry.value as int,
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> writeAll(Map<String, int> values) async {
    final prefs = await _prefs;
    await prefs.setString(_prefsKey, jsonEncode(values));
  }

  Future<void> touch(String url) async {
    final values = await readAll();
    values[url] = DateTime.now().millisecondsSinceEpoch;
    await writeAll(values);
  }

  Future<void> remove(String url) async {
    final values = await readAll();
    values.remove(url);
    await writeAll(values);
  }

  Future<void> removeAll(Iterable<String> urls) async {
    final values = await readAll();
    for (final url in urls) {
      values.remove(url);
    }
    await writeAll(values);
  }
}
