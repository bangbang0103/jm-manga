import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 通用分页列表 Notifier 基类。
///
/// 收敛了 Search / Rankings / Category / AlbumComments 四个分页 Notifier
/// 的公共逻辑：页码跟踪、加载更多去重、`hasMore` 判断、追加合并与错误态。
///
/// 子类只需实现 [fetchPage]、[itemsOf]、[merge]，并在构造函数中决定是否
/// 立即调用 [load]。
abstract class PagedListNotifier<T> extends StateNotifier<AsyncValue<T>> {
  /// 默认分页大小，用于判断当前页拉满后是否还有下一页。
  static const defaultPageSize = 20;

  int _page = 1;
  bool _loadingMore = false;
  bool _hasMore = true;

  PagedListNotifier() : super(const AsyncValue.loading());

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _loadingMore;

  /// 判断 `hasMore` 时使用的页大小，默认 [defaultPageSize]。
  int get pageSize => defaultPageSize;

  /// 拉取第 [page] 页数据。
  Future<T> fetchPage(int page);

  /// 从一页结果中取出条目列表，用于空页和 `hasMore` 判断。
  List<Object?> itemsOf(T pageData);

  /// 把新拉取的一页 [next] 合并到当前状态 [current]（追加模式）。
  /// [current] 为 null 时直接返回 [next]。
  T merge(T? current, T next);

  /// 重新从第一页加载。
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
    try {
      await _fetch(page: _page + 1, append: true);
    } finally {
      _loadingMore = false;
    }
  }

  /// 子类在不需要发起请求时使用：直接置为给定数据并关闭分页。
  @protected
  void completeWithoutResults(T empty) {
    _hasMore = false;
    state = AsyncValue.data(empty);
  }

  Future<void> _fetch({required int page, bool append = false}) async {
    try {
      final results = await fetchPage(page);
      final items = itemsOf(results);
      if (items.isEmpty) {
        _hasMore = false;
      } else {
        _page = page;
        _hasMore = items.length >= pageSize;
      }

      if (mounted) {
        state = AsyncValue.data(
          append ? merge(state.valueOrNull, results) : results,
        );
      }
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }
}

/// 状态本身就是 `List<Item>` 的分页 Notifier，提供默认的 [itemsOf] 与
/// [merge] 实现，子类只需实现 [fetchPage]。
abstract class ListPagedNotifier<Item> extends PagedListNotifier<List<Item>> {
  @override
  List<Item> itemsOf(List<Item> pageData) => pageData;

  @override
  List<Item> merge(List<Item>? current, List<Item> next) => [
    ...current ?? const [],
    ...next,
  ];
}
