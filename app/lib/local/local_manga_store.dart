import '../models/album.dart';
import '../models/reading_progress.dart';
import 'local_database.dart';
import 'local_manga_records.dart';

/// 本地收藏的同步状态。
class FavoriteSyncStatus {
  static const synced = 'synced';
  static const pendingAdd = 'pendingAdd';
  static const pendingRemove = 'pendingRemove';
}

class LocalMangaStore {
  final LocalMangaRecords _records;

  LocalMangaStore({LocalMangaRecords? records})
    : _records = records ?? LocalMangaRecords(LocalDatabase.instance);

  Future<void> saveProgress(String ownerKey, ReadingProgress progress) async {
    await _records.saveProgress(ownerKey, progress);
  }

  Future<List<ReadingProgress>> getRecentProgress(
    String ownerKey, {
    int limit = 20,
  }) async {
    return _records.recentProgress(ownerKey, limit: limit);
  }

  Future<List<ReadingProgress>> getAlbumProgress(
    String ownerKey,
    String albumId,
  ) async {
    return _records.albumProgress(ownerKey, albumId);
  }

  Future<int> deleteRecentProgress(String ownerKey, List<String> albumIds) {
    return _records.deleteAlbumProgressList(ownerKey, albumIds);
  }

  Future<List<ReadingProgress>> searchRecentProgress(
    String ownerKey,
    String query, {
    int limit = 20,
  }) {
    return _records.searchRecentProgress(ownerKey, query, limit: limit);
  }

  /// 添加/更新本地收藏。
  ///
  /// - 新记录或从未同步的记录 → `pendingAdd`（可透传 [syncStatus] 覆盖）。
  /// - 之前是 `pendingRemove`（远程仍有）→ 改为 `synced`，无需再同步。
  /// - 已经是 `synced`/`pendingAdd` → 只更新元数据，保留原状态。
  Future<void> addFavorite(
    String ownerKey,
    AlbumItem item, {
    String syncStatus = FavoriteSyncStatus.pendingAdd,
  }) async {
    final existing = await _findFavorite(ownerKey, item.albumId);
    String targetStatus;

    if (existing != null) {
      final existingStatus = existing.syncStatus;
      if (existingStatus == FavoriteSyncStatus.pendingRemove) {
        targetStatus = FavoriteSyncStatus.synced;
      } else {
        targetStatus = existingStatus ?? syncStatus;
      }
    } else {
      targetStatus = item.syncStatus ?? syncStatus;
    }

    await _records.upsertFavorite(ownerKey, item, syncStatus: targetStatus);
  }

  /// 取消本地收藏。
  ///
  /// - 已同步（`synced`）→ 标记为 `pendingRemove`，保留记录用于后台同步到 JM。
  /// - 未同步（`pendingAdd`）→ 直接删除，无需网络操作。
  /// - 已经是 `pendingRemove` → 无变化。
  Future<bool> removeFavorite(String ownerKey, String albumId) async {
    final existing = await _findFavorite(ownerKey, albumId);
    if (existing == null) return false;

    final status = existing.syncStatus;
    if (status == FavoriteSyncStatus.synced) {
      await _records.upsertFavorite(
        ownerKey,
        existing,
        syncStatus: FavoriteSyncStatus.pendingRemove,
      );
      return true;
    }

    if (status == FavoriteSyncStatus.pendingAdd) {
      return _records.removeFavorite(ownerKey, albumId);
    }

    // pendingRemove：无变化。
    return true;
  }

  Future<void> clearFavorites(String ownerKey) {
    return _records.clearFavorites(ownerKey);
  }

  Future<bool> isFavorite(String ownerKey, String albumId) async {
    final existing = await _findFavorite(ownerKey, albumId);
    return existing != null &&
        existing.syncStatus != FavoriteSyncStatus.pendingRemove;
  }

  Future<List<AlbumItem>> getFavorites(String ownerKey, {int page = 1}) async {
    final records = await _records.favoriteRecords(ownerKey, page: page);
    return records
        .where((r) => r.syncStatus != FavoriteSyncStatus.pendingRemove)
        .toList();
  }

  /// 返回需要同步到 JM 的记录。
  /// `pendingAdd` 需要新增到远端，`pendingRemove` 需要从远端删除。
  Future<List<AlbumItem>> pendingFavorites(String ownerKey) async {
    final records = await _records.allFavorites(ownerKey);
    return records
        .where(
          (r) => {
            FavoriteSyncStatus.pendingAdd,
            FavoriteSyncStatus.pendingRemove,
          }.contains(r.syncStatus),
        )
        .toList();
  }

  /// 把指定记录标记为已同步。
  Future<void> markFavoriteSynced(String ownerKey, String albumId) async {
    final existing = await _findFavorite(ownerKey, albumId);
    if (existing == null) return;
    await _records.upsertFavorite(
      ownerKey,
      existing,
      syncStatus: FavoriteSyncStatus.synced,
    );
  }

  /// 确认已取消收藏同步完成，删除记录。
  Future<void> confirmFavoriteRemoved(String ownerKey, String albumId) async {
    await _records.removeFavorite(ownerKey, albumId);
  }

  /// 批量替换本地收藏列表，统一设置同步状态。
  Future<void> replaceFavorites(
    String ownerKey,
    List<AlbumItem> items, {
    String syncStatus = FavoriteSyncStatus.synced,
  }) async {
    await _records.replaceFavorites(ownerKey, items, syncStatus: syncStatus);
  }

  Future<Map<String, int>> sizes(String ownerKey) => _records.sizes(ownerKey);

  Future<void> saveChapterManifest(ChapterManifest manifest) {
    return _records.upsertChapterManifest(manifest);
  }

  Future<ChapterManifest?> getChapterManifest(String photoId) {
    return _records.chapterManifest(photoId);
  }

  Future<AlbumItem?> _findFavorite(String ownerKey, String albumId) async {
    final all = await _records.allFavorites(ownerKey);
    try {
      return all.firstWhere((item) => item.albumId == albumId);
    } catch (_) {
      return null;
    }
  }
}
