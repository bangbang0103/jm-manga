import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/utils/image_cache_lru_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'jm_image_cache_lru_v1';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<Map<String, dynamic>> readRawPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  test('lazily loads existing values from disk on first access', () async {
    SharedPreferences.setMockInitialValues({
      _prefsKey: jsonEncode({'image:a': 111, 'cover:b': 222}),
    });

    final store = ImageCacheLruStore();
    final values = await store.readAll();

    expect(values, {'image:a': 111, 'cover:b': 222});
    await store.dispose();
  });

  test('readAll returns a copy that callers can mutate safely', () async {
    final store = ImageCacheLruStore();
    await store.touch('image:a');

    final values = await store.readAll();
    values['image:b'] = 1;
    values.remove('image:a');

    final reread = await store.readAll();
    expect(reread.keys, ['image:a']);
    await store.dispose();
  });

  test('keeps changes in memory until the debounce window elapses', () async {
    final store = ImageCacheLruStore();

    await store.touch('image:a');
    await store.touch('image:b');

    // 内存中立即可见。
    final inMemory = await store.readAll();
    expect(inMemory.keys, containsAll(['image:a', 'image:b']));

    // 防抖窗口内磁盘上还没有数据。
    expect(await readRawPrefs(), isEmpty);

    // 窗口过后批量落盘。
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final persisted = await readRawPrefs();
    expect(persisted.keys, containsAll(['image:a', 'image:b']));
    await store.dispose();
  });

  test('remove and removeAll update memory and are persisted', () async {
    final store = ImageCacheLruStore();
    await store.touch('image:a');
    await store.touch('image:b');
    await store.touch('image:c');

    await store.remove('image:a');
    await store.removeAll(['image:b', 'image:c']);
    await store.flush();

    expect(await store.readAll(), isEmpty);
    expect(await readRawPrefs(), isEmpty);
    await store.dispose();
  });

  test('writeAll replaces all values and flush persists immediately', () async {
    final store = ImageCacheLruStore();
    await store.touch('image:stale');

    await store.writeAll({'image:x': 1, 'cover:y': 2});
    await store.flush();

    expect(await store.readAll(), {'image:x': 1, 'cover:y': 2});
    expect(await readRawPrefs(), {'image:x': 1, 'cover:y': 2});
    await store.dispose();
  });

  test('dispose flushes pending changes without waiting for debounce', () async {
    final store = ImageCacheLruStore();
    await store.touch('image:a');

    await store.dispose();

    final persisted = await readRawPrefs();
    expect(persisted.keys, ['image:a']);
  });

  test('flush is a no-op when there are no pending changes', () async {
    final store = ImageCacheLruStore();

    await store.flush();

    expect(await readRawPrefs(), isEmpty);
    await store.dispose();
  });
}
