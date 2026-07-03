import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/painting.dart';

import '../network/jm/jm_client.dart';
import '../network/jm/jm_image_service.dart';
import '../network/jm/jm_session_store.dart';
import '../local/local_manga_store.dart';
import '../models/album.dart';
import '../utils/app_logger.dart';
import '../models/reading_progress.dart';
import 'direct_manga_mapper.dart';
import 'manga_repository.dart';

class DirectMangaRepository implements MangaRepository {
  final JmClient client;
  final JmImageService imageService;
  final LocalMangaStore localStore;
  final JmSessionStore sessionStore;
  final String ownerKey;
  final String? username;
  final String? password;
  final String? proxyUrl;
  bool _sessionLoaded = false;

  DirectMangaRepository({
    required this.client,
    required this.ownerKey,
    this.username,
    this.password,
    this.proxyUrl,
    JmImageService? imageService,
    LocalMangaStore? localStore,
    JmSessionStore? sessionStore,
  }) : imageService =
           imageService ?? JmImageService.forClient(client, proxyUrl: proxyUrl),
       localStore = localStore ?? LocalMangaStore(),
       sessionStore = sessionStore ?? const JmSessionStore();

  @override
  Future<List<AlbumItem>> search(String query, {int page = 1}) async {
    final result = await client.search(query, page: page);
    return result.items
        .map((item) => albumItemFromJm(item, coverUrl: coverUrl(item.id)))
        .toList();
  }

  @override
  Future<List<AlbumItem>> getRankings(
    String type, {
    String category = '0',
    int page = 1,
  }) async {
    final result = await client.ranking(type, category: category, page: page);
    return result.items
        .map((item) => albumItemFromJm(item, coverUrl: coverUrl(item.id)))
        .toList();
  }

  @override
  Future<List<AlbumItem>> getCategories({
    String category = '0',
    String orderBy = 'mr',
    int page = 1,
  }) async {
    final result = await client.categoriesFilter(
      category: category,
      orderBy: orderBy,
      page: page,
    );
    return result.items
        .map((item) => albumItemFromJm(item, coverUrl: coverUrl(item.id)))
        .toList();
  }

  @override
  Future<AlbumDetail> getAlbumDetail(String albumId) async {
    final album = await _withSession(() => client.getAlbum(albumId));
    final isFavorite = await localStore.isFavorite(ownerKey, albumId);
    return albumDetailFromJm(
      album,
      coverUrl: coverUrl(album.id, size: ''),
      isFavorite: isFavorite || album.isFavorite,
    );
  }

  @override
  Future<PhotoDetail> getPhotoDetail(String photoId) async {
    return _withSession(() async {
      final chapter = await client.getChapter(photoId);
      final scrambleId = await client.getScrambleId(photoId);
      final imageUrls = [
        for (final imageName in chapter.imageNames)
          client.imageUrl(chapter.id, imageName, scrambleId: scrambleId),
      ];
      return photoDetailFromJm(chapter, imageUrls);
    });
  }

  @override
  String coverUrl(String albumId, {String size = ''}) {
    return client.coverUrl(albumId, size: size);
  }

  @override
  Map<String, String> get imageHeaders => const {};

  @override
  ImageProvider imageProvider(String url) {
    return JmDecodedImageProvider(url: url, service: imageService);
  }

  @override
  Future<Uint8List> downloadImage(String url) {
    return imageService.loadDecodedBytes(url);
  }

  @override
  Future<List<AlbumItem>> getFavorites({String folderId = '0', int page = 1}) =>
      localStore.getFavorites(ownerKey, page: page);

  @override
  Future<Map<String, dynamic>> syncFavorites({
    String folderId = '0',
    int page = 1,
    bool force = false,
    bool full = false,
  }) async {
    if (!_hasAccount) {
      return {'synced': false, 'reason': 'jm_login_required'};
    }

    if (!full) {
      // 非全量同步仅返回单页信息，当前 UI 不调用此分支。
      final favoritePage = await _withSession(
        () => client.getFavoritePage(page: page, folderId: folderId),
      );
      return {
        'synced': true,
        'count': favoritePage.items.length,
        'page': page,
        'total': favoritePage.total,
      };
    }

    // 全量同步：一次拉取远端收藏，合并本地 pending，整表替换。
    final remoteItems = await _fetchAllRemoteFavorites(folderId: folderId);
    final merge = await _mergePendingIntoRemote(remoteItems);
    await localStore.replaceFavorites(ownerKey, merge.items);

    return {
      'synced': true,
      'count': merge.items.length,
      'failed': merge.failedIds,
      'partial': merge.failedIds.isNotEmpty,
    };
  }

  Future<List<AlbumItem>> _fetchAllRemoteFavorites({
    String folderId = '0',
  }) async {
    final items = <AlbumItem>[];
    var currentPage = 1;
    var total = 0;
    while (true) {
      final favoritePage = await _withSession(
        () => client.getFavoritePage(page: currentPage, folderId: folderId),
      );
      total = favoritePage.total;
      items.addAll(
        favoritePage.items.map(
          (item) => albumItemFromJm(item, coverUrl: coverUrl(item.id)),
        ),
      );
      if (favoritePage.items.isEmpty || items.length >= total) {
        break;
      }
      currentPage += 1;
    }
    return items;
  }

  Future<({List<AlbumItem> items, List<String> failedIds})>
  _mergePendingIntoRemote(List<AlbumItem> remoteItems) async {
    final pending = await localStore.pendingFavorites(ownerKey);
    final remoteIds = remoteItems.map((item) => item.albumId).toSet();
    final failedIds = <String>[];
    final pendingAdds = <AlbumItem>[];
    final finalRemoteItems = remoteItems.toList();

    for (final item in pending) {
      final status = item.syncStatus;
      final existsInRemote = remoteIds.contains(item.albumId);

      if (status == FavoriteSyncStatus.pendingAdd) {
        if (existsInRemote) {
          // 远端已存在，无需 toggle，本地会随远端记录标记为 synced。
          continue;
        }
        try {
          await _withSession(() => client.toggleFavorite(item.albumId));
          pendingAdds.add(item.copyWith(syncStatus: FavoriteSyncStatus.synced));
        } catch (e, st) {
          globalLogger.w(
            'Failed to add favorite ${item.albumId} to JM',
            error: e,
            stackTrace: st,
          );
          failedIds.add(item.albumId);
          // 保留 pendingAdd，下次再试。
          pendingAdds.add(item);
        }
      } else if (status == FavoriteSyncStatus.pendingRemove) {
        if (!existsInRemote) {
          // 远端已不存在，无需 toggle，本地直接丢弃。
          continue;
        }
        try {
          await _withSession(() => client.toggleFavorite(item.albumId));
          finalRemoteItems.removeWhere((i) => i.albumId == item.albumId);
          remoteIds.remove(item.albumId);
        } catch (e, st) {
          globalLogger.w(
            'Failed to remove favorite ${item.albumId} from JM',
            error: e,
            stackTrace: st,
          );
          failedIds.add(item.albumId);
          // 保留 pendingRemove，避免本地记录丢失。
          final index = finalRemoteItems.indexWhere(
            (i) => i.albumId == item.albumId,
          );
          if (index >= 0) {
            finalRemoteItems[index] = finalRemoteItems[index].copyWith(
              syncStatus: FavoriteSyncStatus.pendingRemove,
            );
          }
        }
      }
    }

    final merged = [...pendingAdds, ...finalRemoteItems];
    return (items: merged, failedIds: failedIds);
  }

  @override
  Future<Map<String, dynamic>> toggleFavorite(
    String albumId, {
    AlbumItem? item,
  }) async {
    final existing = await localStore.isFavorite(ownerKey, albumId);
    final willBeFavorited = !existing;

    if (willBeFavorited) {
      await localStore.addFavorite(
        ownerKey,
        item ?? AlbumItem(albumId: albumId, title: albumId, tags: const []),
      );
    } else {
      await localStore.removeFavorite(ownerKey, albumId);
    }

    return {'favorited': willBeFavorited};
  }

  @override
  Future<List<ReadingProgress>> getRecentProgress() {
    return localStore.getRecentProgress(ownerKey);
  }

  @override
  Future<List<ReadingProgress>> searchRecentProgress(String query) {
    return localStore.searchRecentProgress(ownerKey, query);
  }

  @override
  Future<List<ReadingProgress>> getAlbumProgress(String albumId) {
    return localStore.getAlbumProgress(ownerKey, albumId);
  }

  @override
  Future<void> syncProgress(ReadingProgress progress) {
    return localStore.saveProgress(ownerKey, progress);
  }

  @override
  Future<void> deleteRecentProgress(List<String> albumIds) async {
    await localStore.deleteRecentProgress(ownerKey, albumIds);
  }

  @override
  Future<Map<String, dynamic>> checkHealth() async => {'status': 'ok'};

  @override
  Future<Map<String, dynamic>> validateConnection() => checkHealth();

  @override
  Future<Map<String, dynamic>> loginToJm(
    String username,
    String password,
  ) async {
    return _loginToClient(username, password, persist: true);
  }

  @override
  Future<Map<String, dynamic>> testJmLogin(String username, String password) {
    return _loginToClient(username, password, persist: false);
  }

  bool get _hasAccount => username != null && username!.trim().isNotEmpty;

  bool get _canRelogin =>
      _hasAccount && password != null && password!.isNotEmpty;

  Future<void> _ensureSession() async {
    if (!_hasAccount || _sessionLoaded) return;
    final cookies = await sessionStore.readCookies(username!);
    if (cookies.isNotEmpty) {
      client.setCookies(cookies);
    }
    _sessionLoaded = true;
  }

  Future<T> _withSession<T>(Future<T> Function() action) async {
    await _ensureSession();
    var retried = false;
    while (true) {
      try {
        final result = await action();
        await _persistSessionCookies();
        return result;
      } on JmApiException catch (e) {
        if (!e.isLoginRequired || !_canRelogin || retried) {
          rethrow;
        }
        await _loginToClient(username!, password!, persist: true);
        retried = true;
      } on DioException catch (e) {
        if (e.response?.statusCode != 401 || !_canRelogin || retried) {
          rethrow;
        }
        await _loginToClient(username!, password!, persist: true);
        retried = true;
      }
    }
  }

  Future<void> _persistSessionCookies() async {
    if (!_hasAccount || client.cookies.isEmpty) return;
    await sessionStore.writeCookies(username!, client.cookies);
  }

  Future<Map<String, dynamic>> _loginToClient(
    String username,
    String password, {
    required bool persist,
  }) async {
    final result = await client.login(username, password);
    if (persist) {
      await sessionStore.writeCookies(username, client.cookies);
      _sessionLoaded = true;
    }
    return {
      'status': 'ok',
      'username': result.username.isEmpty ? username : result.username,
      'uid': result.uid,
      'album_favorites': result.favorites,
      'album_favorites_max': result.favoritesMax,
    };
  }
}
