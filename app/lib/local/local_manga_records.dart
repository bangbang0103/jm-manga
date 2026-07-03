import 'dart:io';

import 'package:sqflite/sqflite.dart';

import '../models/album.dart';
import '../models/reading_progress.dart';

class LocalMangaRecords {
  static const favoritePageSize = 50;

  final Future<Database> _dbFuture;

  LocalMangaRecords(this._dbFuture);

  Future<Database> get _db async => await _dbFuture;

  // Progress

  Future<void> saveProgress(String ownerKey, ReadingProgress progress) async {
    final db = await _db;
    await db.insert(
      'reading_progress',
      _progressToRow(ownerKey, progress),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ReadingProgress>> recentProgress(
    String ownerKey, {
    int limit = 20,
  }) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT r.*
      FROM reading_progress r
      INNER JOIN (
        SELECT album_id, MAX(last_read_at) AS max_last_read_at
        FROM reading_progress
        WHERE owner_key = ?
        GROUP BY album_id
      ) latest ON r.album_id = latest.album_id AND r.last_read_at = latest.max_last_read_at
      WHERE r.owner_key = ?
      ORDER BY r.last_read_at DESC
      LIMIT ?
    ''', [ownerKey, ownerKey, limit]);
    return rows.map(_rowToProgress).toList();
  }

  Future<List<ReadingProgress>> albumProgress(
    String ownerKey,
    String albumId,
  ) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT r.*
      FROM reading_progress r
      INNER JOIN (
        SELECT photo_id, MAX(last_read_at) AS max_last_read_at
        FROM reading_progress
        WHERE owner_key = ? AND album_id = ?
        GROUP BY photo_id
      ) latest ON r.photo_id = latest.photo_id AND r.last_read_at = latest.max_last_read_at
      WHERE r.owner_key = ? AND r.album_id = ?
      ORDER BY r.last_read_at DESC
    ''', [ownerKey, albumId, ownerKey, albumId]);
    return rows.map(_rowToProgress).toList();
  }

  Future<int> deleteAlbumProgress(String ownerKey, String albumId) async {
    final db = await _db;
    return db.delete(
      'reading_progress',
      where: 'owner_key = ? AND album_id = ?',
      whereArgs: [ownerKey, albumId],
    );
  }

  Future<int> deleteAlbumProgressList(
    String ownerKey,
    List<String> albumIds,
  ) async {
    if (albumIds.isEmpty) return 0;
    final db = await _db;
    var total = 0;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final albumId in albumIds) {
        batch.delete(
          'reading_progress',
          where: 'owner_key = ? AND album_id = ?',
          whereArgs: [ownerKey, albumId],
        );
      }
      final results = await batch.commit(continueOnError: false);
      for (final result in results) {
        if (result is int) total += result;
      }
    });
    return total;
  }

  Future<List<ReadingProgress>> searchRecentProgress(
    String ownerKey,
    String query, {
    int limit = 20,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return recentProgress(ownerKey, limit: limit);
    }
    final db = await _db;
    final pattern = '%$trimmed%';
    final rows = await db.rawQuery('''
      SELECT r.*
      FROM reading_progress r
      INNER JOIN (
        SELECT album_id, MAX(last_read_at) AS max_last_read_at
        FROM reading_progress
        WHERE owner_key = ? AND LOWER(title) LIKE LOWER(?)
        GROUP BY album_id
      ) latest ON r.album_id = latest.album_id AND r.last_read_at = latest.max_last_read_at
      WHERE r.owner_key = ?
      ORDER BY r.last_read_at DESC
      LIMIT ?
    ''', [ownerKey, pattern, ownerKey, limit]);
    return rows.map(_rowToProgress).toList();
  }

  // Favorites

  Future<void> upsertFavorite(
    String ownerKey,
    AlbumItem item, {
    String syncStatus = '',
  }) async {
    final db = await _db;
    await db.insert(
      'favorites',
      _favoriteToRow(ownerKey, item, syncStatus: syncStatus),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> removeFavorite(String ownerKey, String albumId) async {
    final db = await _db;
    final count = await db.delete(
      'favorites',
      where: 'owner_key = ? AND album_id = ?',
      whereArgs: [ownerKey, albumId],
    );
    return count > 0;
  }

  Future<void> clearFavorites(String ownerKey) async {
    final db = await _db;
    await db.delete(
      'favorites',
      where: 'owner_key = ?',
      whereArgs: [ownerKey],
    );
  }

  Future<bool> favoriteExists(String ownerKey, String albumId) async {
    final db = await _db;
    final rows = await db.query(
      'favorites',
      columns: ['1'],
      where: 'owner_key = ? AND album_id = ?',
      whereArgs: [ownerKey, albumId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<List<AlbumItem>> allFavorites(String ownerKey) async {
    final db = await _db;
    final rows = await db.query(
      'favorites',
      where: 'owner_key = ?',
      whereArgs: [ownerKey],
      orderBy: 'cached_at DESC',
    );
    return rows.map(_rowToFavorite).toList();
  }

  Future<List<AlbumItem>> favoriteRecords(
    String ownerKey, {
    int page = 1,
  }) async {
    final db = await _db;
    final safePage = page < 1 ? 1 : page;
    final offset = (safePage - 1) * favoritePageSize;
    final rows = await db.query(
      'favorites',
      where: 'owner_key = ?',
      whereArgs: [ownerKey],
      orderBy: 'cached_at DESC',
      limit: favoritePageSize,
      offset: offset,
    );
    return rows.map(_rowToFavorite).toList();
  }

  Future<void> replaceFavorites(
    String ownerKey,
    List<AlbumItem> items, {
    String syncStatus = '',
  }) async {
    final db = await _db;
    final baseCachedAt = DateTime.now().toUtc();
    await db.transaction((txn) async {
      await txn.delete(
        'favorites',
        where: 'owner_key = ?',
        whereArgs: [ownerKey],
      );
      // 列表中排在前面的项具有更大的 cached_at，按 DESC 排序后会保持原列表顺序。
      for (var i = 0; i < items.length; i++) {
        final row = _favoriteToRow(
          ownerKey,
          items[i],
          syncStatus: items[i].syncStatus ?? syncStatus,
          cachedAt: baseCachedAt.add(
            Duration(milliseconds: items.length - 1 - i),
          ),
        );
        await txn.insert('favorites', row);
      }
    });
  }

  // Metadata

  Future<Map<String, int>> sizes(String ownerKey) async {
    final db = await _db;
    final path = db.path;
    var fileSize = 0;
    if (path != ':memory:' && path.isNotEmpty) {
      try {
        fileSize = await File(path).length();
      } catch (_) {
        // ignore
      }
    }
    return {
      'covers': 0,
      'images': 0,
      'database': fileSize,
    };
  }

  // Helpers

  Map<String, dynamic> _progressToRow(
    String ownerKey,
    ReadingProgress progress,
  ) {
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'owner_key': ownerKey,
      'album_id': progress.albumId,
      'photo_id': progress.photoId,
      'title': progress.title,
      'image_index': progress.imageIndex,
      'is_finished': progress.isFinished ? 1 : 0,
      'last_read_at': progress.lastReadAt,
      'episode_index': progress.episodeIndex,
      'page_count': progress.pageCount,
      'cached_at': now,
    };
  }

  ReadingProgress _rowToProgress(Map<String, dynamic> row) {
    return ReadingProgress.fromJson({
      'album_id': row['album_id'],
      'photo_id': row['photo_id'],
      'title': row['title'],
      'image_index': row['image_index'],
      'is_finished': row['is_finished'] == 1,
      'last_read_at': row['last_read_at'],
      'episode_index': row['episode_index'],
      'page_count': row['page_count'],
    });
  }

  Map<String, dynamic> _favoriteToRow(
    String ownerKey,
    AlbumItem item, {
    required String syncStatus,
    DateTime? cachedAt,
  }) {
    final timestamp = (cachedAt ?? DateTime.now().toUtc()).toIso8601String();
    return {
      'owner_key': ownerKey,
      'album_id': item.albumId,
      'title': item.title,
      'cover_url': item.coverUrl,
      'sync_status': syncStatus,
      'cached_at': timestamp,
    };
  }

  AlbumItem _rowToFavorite(Map<String, dynamic> row) {
    return AlbumItem(
      albumId: row['album_id']?.toString() ?? '',
      title: row['title']?.toString() ?? '',
      tags: const [],
      coverUrl: row['cover_url']?.toString(),
      syncStatus: row['sync_status']?.toString(),
    );
  }
}
