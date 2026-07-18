import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/providers/paged_list_notifier.dart';

class _IntListNotifier extends ListPagedNotifier<int> {
  /// page -> items；缺省返回空列表。
  final Map<int, List<int>> pages;
  final requestedPages = <int>[];

  _IntListNotifier(this.pages);

  @override
  Future<List<int>> fetchPage(int page) async {
    requestedPages.add(page);
    return pages[page] ?? const [];
  }
}

class _SmallPageNotifier extends _IntListNotifier {
  _SmallPageNotifier(super.pages);

  @override
  int get pageSize => 2;
}

void main() {
  group('PagedListNotifier', () {
    test('load fetches first page and exposes data', () async {
      final notifier = _IntListNotifier({
        1: [1, 2, 3],
      });
      addTearDown(notifier.dispose);

      await notifier.load();

      expect(notifier.state.valueOrNull, [1, 2, 3]);
      expect(notifier.hasMore, isFalse);
      expect(notifier.requestedPages, [1]);
    });

    test('full page keeps hasMore true', () async {
      final notifier = _IntListNotifier({
        1: List.generate(PagedListNotifier.defaultPageSize, (i) => i),
      });
      addTearDown(notifier.dispose);

      await notifier.load();

      expect(notifier.hasMore, isTrue);
    });

    test('loadMore appends next page and advances', () async {
      final notifier = _IntListNotifier({
        1: List.generate(PagedListNotifier.defaultPageSize, (i) => i),
        2: [100, 101],
      });
      addTearDown(notifier.dispose);
      await notifier.load();

      await notifier.loadMore();

      expect(notifier.requestedPages, [1, 2]);
      expect(notifier.state.valueOrNull?.length, 22);
      expect(notifier.state.valueOrNull?.last, 101);
      // 第二页不满，没有更多数据。
      expect(notifier.hasMore, isFalse);
    });

    test('loadMore is a no-op when there is no more data', () async {
      final notifier = _IntListNotifier({
        1: [1],
      });
      addTearDown(notifier.dispose);
      await notifier.load();

      await notifier.loadMore();

      expect(notifier.requestedPages, [1]);
      expect(notifier.state.valueOrNull, [1]);
    });

    test('concurrent loadMore only fetches once', () async {
      final notifier = _IntListNotifier({
        1: List.generate(PagedListNotifier.defaultPageSize, (i) => i),
        2: [100],
      });
      addTearDown(notifier.dispose);
      await notifier.load();

      await Future.wait([notifier.loadMore(), notifier.loadMore()]);

      expect(notifier.requestedPages, [1, 2]);
    });

    test('reload resets to first page', () async {
      final notifier = _IntListNotifier({
        1: List.generate(PagedListNotifier.defaultPageSize, (i) => i),
        2: [100],
      });
      addTearDown(notifier.dispose);
      await notifier.load();
      await notifier.loadMore();

      await notifier.load();

      expect(notifier.requestedPages, [1, 2, 1]);
      expect(
        notifier.state.valueOrNull?.length,
        PagedListNotifier.defaultPageSize,
      );
      expect(notifier.hasMore, isTrue);
    });

    test('fetch failure surfaces as AsyncValue.error', () async {
      final notifier = _FailingNotifier();
      addTearDown(notifier.dispose);

      await notifier.load();

      expect(notifier.state.hasError, isTrue);
    });

    test('custom pageSize drives hasMore', () async {
      final notifier = _SmallPageNotifier({
        1: [1, 2],
      });
      addTearDown(notifier.dispose);

      await notifier.load();

      expect(notifier.hasMore, isTrue);
    });

    test('completeWithoutResults sets empty data and disables paging', () {
      final notifier = _EmptyNotifier();
      addTearDown(notifier.dispose);

      expect(notifier.state.valueOrNull, isEmpty);
      expect(notifier.hasMore, isFalse);
    });
  });
}

class _FailingNotifier extends ListPagedNotifier<int> {
  @override
  Future<List<int>> fetchPage(int page) => Future.error(StateError('boom'));
}

class _EmptyNotifier extends ListPagedNotifier<int> {
  _EmptyNotifier() {
    completeWithoutResults(const []);
  }

  @override
  Future<List<int>> fetchPage(int page) async => const [];
}
