import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 管理图片缓存的 LRU 元数据。
///
/// 以 url 为 key，最后一次访问时间戳（毫秒）为 value 存到 SharedPreferences。
///
/// 实现为内存缓存 + 防抖落盘：首次访问时懒加载全量数据到内存 Map，
/// 之后的读写只操作内存；每次变更后约 [_flushDebounce] 批量写回磁盘，
/// 避免每张图片都做一次全量 JSON 编解码和磁盘 I/O。
///
/// Trade-off：防抖窗口内若进程被杀，最多丢失一个窗口的 LRU 元数据变更，
/// 仅影响缓存淘汰顺序（可能误删刚访问过的文件），图片文件本身不受影响。
class ImageCacheLruStore {
  static const _prefsKey = 'jm_image_cache_lru_v1';
  static const _flushDebounce = Duration(milliseconds: 500);

  Map<String, int>? _values;
  Future<Map<String, int>>? _loading;
  Timer? _flushTimer;
  bool _dirty = false;

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  /// 懒加载内存缓存。并发的首次访问共享同一次磁盘读取。
  Future<Map<String, int>> _load() {
    final cached = _values;
    if (cached != null) return Future.value(cached);
    return _loading ??= _readFromDisk().then((values) {
      _values = values;
      _loading = null;
      return values;
    });
  }

  Future<Map<String, int>> _readFromDisk() async {
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

  /// 返回内存数据的副本，调用方可以自由修改返回值。
  Future<Map<String, int>> readAll() async {
    return Map<String, int>.of(await _load());
  }

  Future<void> writeAll(Map<String, int> values) async {
    // 先等待可能正在进行中的首次磁盘读取完成，避免被旧数据覆盖。
    await _load();
    _values = Map<String, int>.of(values);
    _scheduleFlush();
  }

  Future<void> touch(String url) async {
    final values = await _load();
    values[url] = DateTime.now().millisecondsSinceEpoch;
    _scheduleFlush();
  }

  Future<void> remove(String url) async {
    final values = await _load();
    values.remove(url);
    _scheduleFlush();
  }

  Future<void> removeAll(Iterable<String> urls) async {
    final values = await _load();
    for (final url in urls) {
      values.remove(url);
    }
    _scheduleFlush();
  }

  void _scheduleFlush() {
    _dirty = true;
    _flushTimer?.cancel();
    _flushTimer = Timer(_flushDebounce, () {
      _flushTimer = null;
      unawaited(_persistIfDirty());
    });
  }

  /// 立即把内存中的脏数据写回磁盘，并取消防抖计时器。
  /// 供测试或应用退出前清理时使用。
  Future<void> flush() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    await _persistIfDirty();
  }

  /// 等价于 [flush]：取消防抖计时器并写回未落盘的变更。
  Future<void> dispose() => flush();

  Future<void> _persistIfDirty() async {
    if (!_dirty) return;
    final values = _values;
    _dirty = false;
    if (values == null) return;
    try {
      final prefs = await _prefs;
      await prefs.setString(_prefsKey, jsonEncode(values));
    } catch (_) {
      // 落盘失败仅影响 LRU 顺序，不影响图片文件，下次变更时会重试。
      _dirty = true;
    }
  }
}
