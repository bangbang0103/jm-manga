import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/manga_repository.dart';
import '../models/album.dart';
import '../models/reading_progress.dart';
import '../utils/tag_query_parser.dart';
import 'repository_provider.dart';

final searchProvider =
    StateNotifierProvider.family<
      SearchNotifier,
      AsyncValue<List<AlbumItem>>,
      SearchRequest
    >((ref, request) {
      final repo = ref.watch(apiRepositoryProvider);
      return SearchNotifier(repo, request);
    });

class SearchNotifier extends StateNotifier<AsyncValue<List<AlbumItem>>> {
  final MangaRepository repo;
  final SearchRequest request;
  int _page = 1;
  bool _loadingMore = false;
  bool _hasMore = true;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _loadingMore;

  SearchNotifier(this.repo, this.request)
    : super(const AsyncValue.loading()) {
    if (request.hasSearchTerms) {
      search();
    } else {
      _hasMore = false;
      state = const AsyncValue.data([]);
    }
  }

  Future<void> search() async {
    _page = 1;
    _hasMore = true;
    state = const AsyncValue.loading();
    await _fetch(page: _page);
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    try {
      await _fetch(page: _page + 1, append: true);
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> _fetch({required int page, bool append = false}) async {
    try {
      final results = await repo.search(request.effectiveQuery, page: page);
      if (results.isEmpty) {
        _hasMore = false;
      } else {
        _page = page;
        _hasMore = results.length >= 20;
      }

      if (mounted) {
        if (append) {
          final current = state.valueOrNull ?? [];
          state = AsyncValue.data([...current, ...results]);
        } else {
          state = AsyncValue.data(results);
        }
      }
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }
}

class RankingsKey {
  final String type;
  final String category;

  const RankingsKey(this.type, this.category);

  @override
  bool operator ==(Object other) =>
      other is RankingsKey && other.type == type && other.category == category;

  @override
  int get hashCode => Object.hash(type, category);
}

final rankingsProvider =
    StateNotifierProvider.family<
      RankingsNotifier,
      AsyncValue<List<AlbumItem>>,
      RankingsKey
    >((ref, key) {
      final repo = ref.watch(apiRepositoryProvider);
      return RankingsNotifier(repo, key);
    });

class RankingsNotifier extends StateNotifier<AsyncValue<List<AlbumItem>>> {
  final MangaRepository repo;
  final RankingsKey key;
  int _page = 1;
  bool _loadingMore = false;
  bool _hasMore = true;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _loadingMore;

  RankingsNotifier(this.repo, this.key)
    : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    _page = 1;
    _hasMore = true;
    state = const AsyncValue.loading();
    await _fetch(page: _page);
  }

  Future<void> refresh() => load();

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    await _fetch(page: _page + 1, append: true);
    _loadingMore = false;
  }

  Future<void> _fetch({required int page, bool append = false}) async {
    try {
      final results = await repo.getRankings(
        key.type,
        category: key.category,
        page: page,
      );
      if (results.isEmpty) {
        _hasMore = false;
      } else {
        _page = page;
        _hasMore = results.length >= 20;
      }
      if (mounted) {
        if (append) {
          final current = state.valueOrNull ?? [];
          state = AsyncValue.data([...current, ...results]);
        } else {
          state = AsyncValue.data(results);
        }
      }
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }
}

class CategoryKey {
  final String category;
  final String orderBy;

  const CategoryKey(this.category, this.orderBy);

  @override
  bool operator ==(Object other) =>
      other is CategoryKey &&
      other.category == category &&
      other.orderBy == orderBy;

  @override
  int get hashCode => Object.hash(category, orderBy);
}

final categoryProvider =
    StateNotifierProvider.family<
      CategoryNotifier,
      AsyncValue<List<AlbumItem>>,
      CategoryKey
    >((ref, key) {
      final repo = ref.watch(apiRepositoryProvider);
      // 分类数据在首次加载后保持存活，避免 Home 滚动出视口再滑回时重复请求。
      ref.keepAlive();
      return CategoryNotifier(repo, key);
    });

class CategoryNotifier extends StateNotifier<AsyncValue<List<AlbumItem>>> {
  final MangaRepository repo;
  final CategoryKey key;
  int _page = 1;
  bool _loadingMore = false;
  bool _hasMore = true;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _loadingMore;

  CategoryNotifier(this.repo, this.key)
    : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    _page = 1;
    _hasMore = true;
    state = const AsyncValue.loading();
    await _fetch(page: _page);
  }

  Future<void> refresh() => load();

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    await _fetch(page: _page + 1, append: true);
    _loadingMore = false;
  }

  Future<void> _fetch({required int page, bool append = false}) async {
    try {
      final results = await repo.getCategories(
        category: key.category,
        orderBy: key.orderBy,
        page: page,
      );
      if (results.isEmpty) {
        _hasMore = false;
      } else {
        _page = page;
        _hasMore = results.length >= 20;
      }
      if (mounted) {
        if (append) {
          final current = state.valueOrNull ?? [];
          state = AsyncValue.data([...current, ...results]);
        } else {
          state = AsyncValue.data(results);
        }
      }
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }
}

final albumDetailProvider = FutureProvider.family<AlbumDetail, String>((
  ref,
  albumId,
) async {
  final repo = ref.watch(apiRepositoryProvider);
  return repo.getAlbumDetail(albumId);
});

final photoDetailProvider = FutureProvider.family<PhotoDetail, String>((
  ref,
  photoId,
) async {
  final repo = ref.watch(apiRepositoryProvider);
  return repo.getPhotoDetail(photoId);
});

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, AsyncValue<List<AlbumItem>>>((
      ref,
    ) {
      final repo = ref.watch(apiRepositoryProvider);
      return FavoritesNotifier(repo);
    });

final favoriteAlbumIdsProvider = Provider<AsyncValue<Set<String>>>((ref) {
  final favoritesAsync = ref.watch(favoritesProvider);
  return favoritesAsync.when(
    data: (items) => AsyncValue.data({for (final item in items) item.albumId}),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

class FavoritesNotifier extends StateNotifier<AsyncValue<List<AlbumItem>>> {
  final MangaRepository repo;
  int _page = 1;
  bool _loadingMore = false;
  bool _hasMore = true;
  String _query = '';
  List<AlbumItem> _allItems = [];

  FavoritesNotifier(this.repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    if (!mounted) return;
    _page = 1;
    _hasMore = true;
    _query = '';
    _allItems = [];
    state = const AsyncValue.loading();
    await _fetchLocal(page: _page);
  }

  Future<void> refresh() => load();

  Future<Map<String, dynamic>> sync() async {
    if (!mounted) return {'synced': false, 'reason': 'not_mounted'};
    state = const AsyncValue.loading();
    try {
      final result = await repo.syncFavorites(force: true, full: true);
      await load();
      return result;
    } catch (e) {
      await load();
      rethrow;
    }
  }

  void search(String query) {
    _query = query.trim().toLowerCase();
    _applyFilter();
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    final nextPage = _page + 1;
    await _fetchLocal(page: nextPage, append: true);
    _loadingMore = false;
  }

  Future<void> _fetchLocal({required int page, bool append = false}) async {
    try {
      final results = await repo.getFavorites(page: page);
      if (results.isEmpty) {
        _hasMore = false;
      } else {
        _page = page;
        _hasMore = results.length >= 50;
      }
      if (append) {
        _allItems = [..._allItems, ...results];
      } else {
        _allItems = results;
      }
      if (mounted) _applyFilter();
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  void _applyFilter() {
    if (_query.isEmpty) {
      state = AsyncValue.data(_allItems);
      return;
    }
    final filtered = _allItems
        .where((item) => item.title.toLowerCase().contains(_query))
        .toList();
    state = AsyncValue.data(filtered);
  }
}

final readingProgressProvider = StateNotifierProvider<
  RecentReadNotifier,
  AsyncValue<List<ReadingProgress>>
>((ref) {
  final repo = ref.watch(apiRepositoryProvider);
  return RecentReadNotifier(repo);
});

/// Home 最近阅读使用独立的 FutureProvider，避免被 Library 的搜索状态污染。
final homeRecentProgressProvider = FutureProvider<List<ReadingProgress>>((
  ref,
) async {
  final repo = ref.watch(apiRepositoryProvider);
  return repo.getRecentProgress();
});

class RecentReadNotifier
    extends StateNotifier<AsyncValue<List<ReadingProgress>>> {
  final MangaRepository _repo;
  String _query = '';
  Timer? _debounceTimer;

  RecentReadNotifier(this._repo) : super(const AsyncValue.loading()) {
    unawaited(load());
  }

  String get query => _query;

  Future<void> load() async {
    _query = '';
    _cancelDebounce();
    if (!mounted) return;
    state = const AsyncValue.loading();
    await _fetch((repo) => repo.getRecentProgress());
  }

  void search(String query) {
    final trimmed = query.trim();
    _query = query;
    _cancelDebounce();
    if (trimmed.isEmpty) {
      unawaited(load());
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      await _fetch((repo) => repo.searchRecentProgress(trimmed));
    });
  }

  Future<void> refresh() async {
    _cancelDebounce();
    final trimmed = _query.trim();
    if (trimmed.isEmpty) {
      await _fetch((repo) => repo.getRecentProgress());
    } else {
      await _fetch((repo) => repo.searchRecentProgress(trimmed));
    }
  }

  Future<void> delete(List<String> albumIds) async {
    _cancelDebounce();
    await _repo.deleteRecentProgress(albumIds);
    await refresh();
  }

  Future<void> _fetch(
    Future<List<ReadingProgress>> Function(MangaRepository repo) fetch,
  ) async {
    try {
      final results = await fetch(_repo);
      if (mounted) state = AsyncValue.data(results);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  void _cancelDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  @override
  void dispose() {
    _cancelDebounce();
    super.dispose();
  }
}

final albumProgressProvider =
    FutureProvider.family<List<ReadingProgress>, String>((ref, albumId) async {
      final repo = ref.watch(apiRepositoryProvider);
      return repo.getAlbumProgress(albumId);
    });
