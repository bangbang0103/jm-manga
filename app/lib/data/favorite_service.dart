import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/manga_repository.dart';
import '../models/album.dart';
import '../providers/album_providers.dart';
import '../providers/repository_provider.dart';

final favoriteServiceProvider = Provider<FavoriteService>((ref) {
  return FavoriteService(ref.watch(apiRepositoryProvider));
});

/// 轻量 Provider：返回指定漫画是否被本地收藏。
/// 避免为了刷新收藏状态而去 invalidate 整个 album detail。
final favoriteStatusProvider = Provider.family<AsyncValue<bool>, String>((
  ref,
  albumId,
) {
  final favoritesAsync = ref.watch(favoritesProvider);
  return favoritesAsync.when(
    data: (items) =>
        AsyncValue.data(items.any((item) => item.albumId == albumId)),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// 封装收藏相关操作。
///
/// - 切换收藏只操作本地存储，立即返回。
/// - 与 JM 官方的同步由用户在收藏页手动触发。
class FavoriteService {
  final MangaRepository _repo;

  FavoriteService(this._repo);

  /// 切换 [item] 的本地收藏状态。
  /// 返回切换后是否为“已收藏”。
  Future<bool> toggle(AlbumItem item) async {
    final result = await _repo.toggleFavorite(item.albumId, item: item);
    return result['favorited'] == true;
  }

}
