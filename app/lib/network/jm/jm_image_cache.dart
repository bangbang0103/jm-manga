import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../../utils/image_cache_lru_store.dart';
import 'jm_image_metadata.dart';
import 'jm_image_semaphore.dart';

class JmImageCache {
  static const _maxCoverBytes = 256 * 1024 * 1024;
  static const _maxImageBytes = 512 * 1024 * 1024;
  static const _coverStaleDays = 14;
  static const _imageStaleDays = 7;

  /// 写入路径上的 evict 节流：距上次真实清理不足 [_evictMinInterval]
  /// 且写入次数不足 [_evictWriteThreshold] 时跳过，避免每张图片都做
  /// 一次全目录扫描。
  static const _evictMinInterval = Duration(minutes: 10);
  static const _evictWriteThreshold = 20;

  final ImageCacheLruStore _lru;
  Directory? _decodedDir;
  Directory? _coverDir;

  /// evict 串行化锁，沿用 [JmImageSemaphore] 模式，防止并发写入
  /// 同时触发多次全目录扫描。
  final _evictLock = JmImageSemaphore(1);
  final _lastEvictAt = <bool, DateTime>{};
  final _writesSinceEvict = <bool, int>{};

  JmImageCache({ImageCacheLruStore? lru}) : _lru = lru ?? ImageCacheLruStore();

  String pendingKeyFor(String key) {
    return _lruKeyForStorageKey(_primaryStorageKeyFor(key));
  }

  Future<Uint8List?> read(String key) async {
    final primaryStorageKey = _primaryStorageKeyFor(key);
    for (final candidate in _storageKeysForRead(key)) {
      final file = await _fileForStorageKey(
        candidate.storageKey,
        candidate.cover,
      );
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      unawaited(
        _lru
            .touch(_lruKeyForStorageKey(candidate.storageKey))
            .catchError((_) {}),
      );
      if (candidate.storageKey != primaryStorageKey) {
        unawaited(write(key, bytes).catchError((_) {}));
      }
      return bytes;
    }
    return null;
  }

  Future<void> write(String key, Uint8List bytes) async {
    final storageKey = _primaryStorageKeyFor(key);
    final cover = _isCoverUrl(key);
    final file = await _fileForStorageKey(storageKey, cover);
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsBytes(bytes, flush: true);
    await temp.rename(file.path);
    await _lru.touch(_lruKeyForStorageKey(storageKey));
    await _evictIfNeeded(cover);
  }

  /// 主动触发缓存清理（绕过写入路径的节流）。应用冷启动时调用一次即可。
  Future<void> evictIfNeeded() async {
    await _evictIfNeeded(true, force: true);
    await _evictIfNeeded(false, force: true);
  }

  /// 带节流的清理入口：仅在距上次真实清理超过 [_evictMinInterval]，
  /// 或期间写入次数达到 [_evictWriteThreshold] 时才执行完整清理。
  /// [force] 为 true 时无条件执行（冷启动的主动清理）。
  Future<void> _evictIfNeeded(bool cover, {bool force = false}) async {
    await _evictLock.acquire();
    try {
      final writes = (_writesSinceEvict[cover] ?? 0) + 1;
      _writesSinceEvict[cover] = writes;
      final lastEvictAt = _lastEvictAt[cover];
      final intervalElapsed =
          lastEvictAt == null ||
          DateTime.now().difference(lastEvictAt) >= _evictMinInterval;
      if (!force && !intervalElapsed && writes < _evictWriteThreshold) {
        return;
      }
      await _evict(cover);
      _lastEvictAt[cover] = DateTime.now();
      _writesSinceEvict[cover] = 0;
    } finally {
      _evictLock.release();
    }
  }

  Future<void> _evict(bool cover) async {
    final dir = await _directoryFor(cover);
    if (!await dir.exists()) return;

    final maxBytes = cover ? _maxCoverBytes : _maxImageBytes;
    final staleDays = cover ? _coverStaleDays : _imageStaleDays;
    final staleThreshold = DateTime.now()
        .subtract(Duration(days: staleDays))
        .millisecondsSinceEpoch;

    final lru = await _lru.readAll();
    final lruPrefix = cover ? 'cover:' : 'image:';
    final entries = <_CacheEntry>[];
    final urlsToRemoveFromLru = <String>[];
    var totalSize = 0;

    await for (final entity in dir.list(recursive: false, followLinks: false)) {
      if (entity is! File) continue;
      final url = _lruKeyForFile(entity, cover);
      final size = await entity.length();
      totalSize += size;
      final lastAccess = lru[url];
      if (lastAccess == null) {
        // 文件存在但 LRU 中没有：补录为当前时间，避免误删。
        entries.add(
          _CacheEntry(url, entity, size, DateTime.now().millisecondsSinceEpoch),
        );
      } else {
        entries.add(_CacheEntry(url, entity, size, lastAccess));
      }
    }

    // 同步当前类型的 LRU：不要清掉另一类缓存的记录。
    for (final url in lru.keys) {
      if (!url.startsWith(lruPrefix)) continue;
      final exists = entries.any((e) => e.url == url);
      if (!exists) urlsToRemoveFromLru.add(url);
    }
    if (urlsToRemoveFromLru.isNotEmpty) {
      await _lru.removeAll(urlsToRemoveFromLru);
    }

    // 补充新发现的文件到 LRU。
    final newUrls = <String, int>{};
    for (final entry in entries) {
      if (!lru.containsKey(entry.url)) {
        newUrls[entry.url] = entry.lastAccess;
      }
    }
    if (newUrls.isNotEmpty) {
      lru.addAll(newUrls);
      await _lru.writeAll(lru);
    }

    // 智能清理：删除过期未访问文件。
    entries.sort((a, b) => a.lastAccess.compareTo(b.lastAccess));
    final staleEntries = entries
        .where((e) => e.lastAccess < staleThreshold)
        .toList();
    for (final entry in staleEntries) {
      try {
        await entry.file.delete();
        totalSize -= entry.size;
        entries.remove(entry);
        lru.remove(entry.url);
      } catch (_) {
        // ignore
      }
    }

    // 容量清理：按 LRU 删除到上限的 80%。
    final targetBytes = (maxBytes * 0.8).round();
    while (totalSize > maxBytes && entries.isNotEmpty) {
      final oldest = entries.first;
      try {
        await oldest.file.delete();
        totalSize -= oldest.size;
        entries.removeAt(0);
        lru.remove(oldest.url);
      } catch (_) {
        entries.removeAt(0);
      }
    }

    // 确保不超过目标上限（80%）。
    while (totalSize > targetBytes && entries.isNotEmpty) {
      final oldest = entries.first;
      try {
        await oldest.file.delete();
        totalSize -= oldest.size;
        entries.removeAt(0);
        lru.remove(oldest.url);
      } catch (_) {
        entries.removeAt(0);
      }
    }

    await _lru.writeAll(lru);
  }

  String _primaryStorageKeyFor(String url) {
    try {
      final metadata = JmImageMetadata.fromUrl(url);
      if (!metadata.isCover) {
        return 'photos/${metadata.photoId}/${metadata.filename}';
      }
    } catch (_) {
      // Fall back to the legacy full-url key for unsupported URLs.
    }
    return url;
  }

  List<({String storageKey, bool cover})> _storageKeysForRead(String url) {
    final cover = _isCoverUrl(url);
    final primary = _primaryStorageKeyFor(url);
    if (primary == url) {
      return [(storageKey: url, cover: cover)];
    }
    return [
      (storageKey: primary, cover: cover),
      (storageKey: url, cover: cover),
    ];
  }

  String _lruKeyForStorageKey(String storageKey) {
    final digest = md5
        .convert(Uint8List.fromList(storageKey.codeUnits))
        .toString();
    return _isCoverUrl(storageKey) ? 'cover:$digest' : 'image:$digest';
  }

  String _lruKeyForFile(File file, bool cover) {
    final digest = basename(file.path).replaceAll('.jpg', '');
    return cover ? 'cover:$digest' : 'image:$digest';
  }

  Future<File> _fileForStorageKey(String storageKey, bool cover) async {
    final directory = await _directoryFor(cover);
    final digest = md5
        .convert(Uint8List.fromList(storageKey.codeUnits))
        .toString();
    return File('${directory.path}/$digest.jpg');
  }

  Future<Directory> _directoryFor(bool cover) async {
    if (cover) {
      return _coverDir ??= Directory(
        '${(await getTemporaryDirectory()).path}/jm_covers',
      );
    }
    return _decodedDir ??= Directory(
      '${(await getTemporaryDirectory()).path}/jm_decoded_images',
    );
  }

  static bool _isCoverUrl(String url) {
    if (url.contains('/api/v1/covers/')) return true;
    try {
      return JmImageMetadata.fromUrl(url).isCover;
    } catch (_) {
      return false;
    }
  }
}

class _CacheEntry {
  final String url;
  final File file;
  final int size;
  final int lastAccess;

  _CacheEntry(this.url, this.file, this.size, this.lastAccess);
}
