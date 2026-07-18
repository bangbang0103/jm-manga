import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/utils/reader_progress.dart';

ReaderPageVisibility _vis({
  required int index,
  int tick = 1,
  double visiblePixels = 100,
  double centerDistance = 50,
  bool containsViewportCenter = false,
}) {
  return ReaderPageVisibility(
    index: index,
    tick: tick,
    visiblePixels: visiblePixels,
    centerDistance: centerDistance,
    containsViewportCenter: containsViewportCenter,
  );
}

void main() {
  group('resumeTargetIndex', () {
    test('returns null when pageCount is zero', () {
      expect(resumeTargetIndex(3, 0), isNull);
    });

    test('returns null when pageCount is negative', () {
      expect(resumeTargetIndex(3, -2), isNull);
    });

    test('keeps in-range index', () {
      expect(resumeTargetIndex(4, 10), 4);
      expect(resumeTargetIndex(0, 10), 0);
      expect(resumeTargetIndex(9, 10), 9);
    });

    test('clamps negative index to first page', () {
      expect(resumeTargetIndex(-3, 10), 0);
    });

    test('clamps index beyond last page', () {
      expect(resumeTargetIndex(15, 10), 9);
    });

    test('single page always resumes to 0', () {
      expect(resumeTargetIndex(0, 1), 0);
      expect(resumeTargetIndex(7, 1), 0);
    });
  });

  group('isResumableIndex', () {
    test('first page needs no jump', () {
      expect(isResumableIndex(0, 10), isFalse);
    });

    test('negative index is rejected', () {
      expect(isResumableIndex(-1, 10), isFalse);
    });

    test('accepts in-range index after first page', () {
      expect(isResumableIndex(1, 10), isTrue);
      expect(isResumableIndex(9, 10), isTrue);
    });

    test('rejects out-of-range index', () {
      expect(isResumableIndex(10, 10), isFalse);
      expect(isResumableIndex(15, 10), isFalse);
    });

    test('rejects when list is empty', () {
      expect(isResumableIndex(1, 0), isFalse);
    });
  });

  group('canAttemptResumeJump', () {
    test('allows attempts below the cap', () {
      expect(canAttemptResumeJump(0), isTrue);
      expect(canAttemptResumeJump(readerResumeMaxAttempts - 1), isTrue);
    });

    test('stops at the cap', () {
      expect(canAttemptResumeJump(readerResumeMaxAttempts), isFalse);
      expect(canAttemptResumeJump(readerResumeMaxAttempts + 5), isFalse);
    });

    test('cap is 20 frames', () {
      expect(readerResumeMaxAttempts, 20);
    });
  });

  group('isValidPageIndex', () {
    test('rejects empty or negative pageCount', () {
      expect(isValidPageIndex(0, 0), isFalse);
      expect(isValidPageIndex(0, -1), isFalse);
    });

    test('rejects negative index', () {
      expect(isValidPageIndex(-1, 5), isFalse);
    });

    test('accepts first and last page', () {
      expect(isValidPageIndex(0, 1), isTrue);
      expect(isValidPageIndex(4, 5), isTrue);
    });

    test('rejects index at or beyond pageCount', () {
      expect(isValidPageIndex(5, 5), isFalse);
      expect(isValidPageIndex(8, 5), isFalse);
    });
  });

  group('clampedPageChange', () {
    test('returns null when pageCount is invalid', () {
      expect(clampedPageChange(3, currentIndex: 0, pageCount: 0), isNull);
      expect(clampedPageChange(3, currentIndex: 0, pageCount: -2), isNull);
    });

    test('returns null when page does not change', () {
      expect(clampedPageChange(4, currentIndex: 4, pageCount: 10), isNull);
    });

    test('clamps negative index to first page', () {
      expect(clampedPageChange(-2, currentIndex: 3, pageCount: 10), 0);
    });

    test('clamps index beyond last page', () {
      expect(clampedPageChange(99, currentIndex: 3, pageCount: 10), 9);
    });

    test('returns the new index for a normal change', () {
      expect(clampedPageChange(5, currentIndex: 3, pageCount: 10), 5);
    });

    test('reverse scroll back to an earlier page', () {
      expect(clampedPageChange(2, currentIndex: 5, pageCount: 10), 2);
    });

    test('single page never changes from 0', () {
      expect(clampedPageChange(0, currentIndex: 0, pageCount: 1), isNull);
      expect(clampedPageChange(8, currentIndex: 0, pageCount: 1), isNull);
    });
  });

  group('isFinishedPage', () {
    test('last page counts as finished', () {
      expect(isFinishedPage(9, 10), isTrue);
    });

    test('index beyond last page still counts as finished', () {
      expect(isFinishedPage(10, 10), isTrue);
    });

    test('middle page is not finished', () {
      expect(isFinishedPage(8, 10), isFalse);
    });

    test('invalid pageCount is not finished', () {
      expect(isFinishedPage(0, 0), isFalse);
    });

    test('single page counts as finished', () {
      expect(isFinishedPage(0, 1), isTrue);
    });
  });

  group('updateVisiblePages', () {
    test('adds a visible page', () {
      final pages = <int, ReaderPageVisibility>{};
      updateVisiblePages(pages, _vis(index: 2));
      expect(pages[2]?.visiblePixels, 100);
    });

    test('replaces an existing entry', () {
      final pages = <int, ReaderPageVisibility>{2: _vis(index: 2)};
      updateVisiblePages(
        pages,
        _vis(index: 2, visiblePixels: 260, centerDistance: 10),
      );
      expect(pages.length, 1);
      expect(pages[2]?.visiblePixels, 260);
    });

    test('removes the page when visiblePixels is zero', () {
      final pages = <int, ReaderPageVisibility>{2: _vis(index: 2)};
      updateVisiblePages(pages, _vis(index: 2, visiblePixels: 0));
      expect(pages, isEmpty);
    });

    test('removes the page when visiblePixels is negative', () {
      final pages = <int, ReaderPageVisibility>{2: _vis(index: 2)};
      updateVisiblePages(pages, _vis(index: 2, visiblePixels: -5));
      expect(pages, isEmpty);
    });

    test('removing a missing page is a no-op', () {
      final pages = <int, ReaderPageVisibility>{1: _vis(index: 1)};
      updateVisiblePages(pages, _vis(index: 2, visiblePixels: 0));
      expect(pages.length, 1);
    });
  });

  group('currentIndexFromVisibility', () {
    test('returns null when nothing is visible', () {
      expect(
        currentIndexFromVisibility(const [], currentTick: 1, pageCount: 10),
        isNull,
      );
    });

    test('ignores snapshots from a stale tick', () {
      final pages = [_vis(index: 3, tick: 1)];
      expect(
        currentIndexFromVisibility(pages, currentTick: 2, pageCount: 10),
        isNull,
      );
    });

    test('ignores pages with zero visible pixels', () {
      final pages = [
        _vis(index: 3, visiblePixels: 0),
        _vis(index: 4, visiblePixels: -1),
      ];
      expect(
        currentIndexFromVisibility(pages, currentTick: 1, pageCount: 10),
        isNull,
      );
    });

    test('ignores out-of-range indices', () {
      final pages = [
        _vis(index: -1),
        _vis(index: 10),
        _vis(index: 4, containsViewportCenter: true),
      ];
      expect(
        currentIndexFromVisibility(pages, currentTick: 1, pageCount: 10),
        4,
      );
    });

    test('returns null when pageCount is invalid', () {
      final pages = [_vis(index: 0, containsViewportCenter: true)];
      expect(
        currentIndexFromVisibility(pages, currentTick: 1, pageCount: 0),
        isNull,
      );
    });

    test('single visible page becomes current', () {
      final pages = [_vis(index: 7, tick: 3)];
      expect(
        currentIndexFromVisibility(pages, currentTick: 3, pageCount: 10),
        7,
      );
    });

    test('prefers the page containing the viewport center', () {
      final pages = [
        _vis(index: 2, visiblePixels: 500, centerDistance: 280),
        _vis(index: 3, visiblePixels: 40, containsViewportCenter: true),
      ];
      expect(
        currentIndexFromVisibility(pages, currentTick: 1, pageCount: 10),
        3,
      );
    });

    test('picks the nearest page when several contain the center', () {
      final pages = [
        _vis(index: 3, centerDistance: 120, containsViewportCenter: true),
        _vis(index: 4, centerDistance: 30, containsViewportCenter: true),
      ];
      expect(
        currentIndexFromVisibility(pages, currentTick: 1, pageCount: 10),
        4,
      );
    });

    test('falls back to the largest visible area', () {
      final pages = [
        _vis(index: 2, visiblePixels: 120, centerDistance: 10),
        _vis(index: 3, visiblePixels: 300, centerDistance: 400),
      ];
      expect(
        currentIndexFromVisibility(pages, currentTick: 1, pageCount: 10),
        3,
      );
    });

    test('breaks visible-area ties by center distance', () {
      final pages = [
        _vis(index: 2, visiblePixels: 200, centerDistance: 300),
        _vis(index: 3, visiblePixels: 200, centerDistance: 90),
      ];
      expect(
        currentIndexFromVisibility(pages, currentTick: 1, pageCount: 10),
        3,
      );
    });

    test('breaks full ties by lower index', () {
      final pages = [
        _vis(index: 5, visiblePixels: 200, centerDistance: 90),
        _vis(index: 3, visiblePixels: 200, centerDistance: 90),
      ];
      expect(
        currentIndexFromVisibility(pages, currentTick: 1, pageCount: 10),
        3,
      );
    });

    test('reverse scrolling moves current page back up', () {
      // 模拟向上滚动：上一页进入视口中心，即使它后写入集合也应胜出。
      final pages = [
        _vis(index: 6, visiblePixels: 400, centerDistance: 200),
        _vis(index: 5, visiblePixels: 120, containsViewportCenter: true),
      ];
      expect(
        currentIndexFromVisibility(pages, currentTick: 1, pageCount: 10),
        5,
      );
    });
  });

  group('estimateItemExtents', () {
    test('returns null when viewport width is not positive', () {
      expect(
        estimateItemExtents(
          urls: const ['a'],
          viewportWidth: 0,
          fallbackAspectRatio: 0.7,
          imageAspectRatios: const {},
        ),
        isNull,
      );
      expect(
        estimateItemExtents(
          urls: const ['a'],
          viewportWidth: -10,
          fallbackAspectRatio: 0.7,
          imageAspectRatios: const {},
        ),
        isNull,
      );
    });

    test('empty url list yields empty extents', () {
      final estimate = estimateItemExtents(
        urls: const [],
        viewportWidth: 800,
        fallbackAspectRatio: 0.7,
        imageAspectRatios: const {},
      )!;
      expect(estimate.fallbackExtent, closeTo(800 / 0.7, 0.001));
      expect(estimate.itemExtents, isEmpty);
    });

    test('uses known aspect ratios and fallback for unknown urls', () {
      final estimate = estimateItemExtents(
        urls: const ['a', 'b', 'c'],
        viewportWidth: 800,
        fallbackAspectRatio: 0.7,
        imageAspectRatios: const {'a': 0.5, 'c': 2.0},
      )!;
      expect(estimate.itemExtents.length, 3);
      expect(estimate.itemExtents[0], closeTo(1600, 0.001));
      expect(estimate.itemExtents[1], closeTo(800 / 0.7, 0.001));
      expect(estimate.itemExtents[2], closeTo(400, 0.001));
    });
  });

  group('estimatedOffsetForIndex', () {
    test('first page has zero offset', () {
      expect(
        estimatedOffsetForIndex(
          0,
          itemExtents: const [10, 20],
          fallbackExtent: 100,
        ),
        0,
      );
    });

    test('negative index has zero offset', () {
      expect(
        estimatedOffsetForIndex(
          -3,
          itemExtents: const [10, 20],
          fallbackExtent: 100,
        ),
        0,
      );
    });

    test('falls back to uniform extent when estimates are empty', () {
      expect(
        estimatedOffsetForIndex(3, itemExtents: const [], fallbackExtent: 100),
        300,
      );
    });

    test('sums extents before the target index', () {
      expect(
        estimatedOffsetForIndex(
          2,
          itemExtents: const [10, 20, 30],
          fallbackExtent: 100,
        ),
        30,
      );
    });

    test('clamps index beyond the estimated list', () {
      expect(
        estimatedOffsetForIndex(
          10,
          itemExtents: const [10, 20, 30],
          fallbackExtent: 100,
        ),
        60,
      );
    });
  });

  group('preloadRange', () {
    test('returns null when there are no pages', () {
      expect(
        preloadRange(currentIndex: 0, urlCount: 0, preloadCount: 5),
        isNull,
      );
    });

    test('single page preloads only itself', () {
      final range = preloadRange(
        currentIndex: 0,
        urlCount: 1,
        preloadCount: 5,
      )!;
      expect(range.start, 0);
      expect(range.end, 0);
    });

    test('preloads forward from the current page', () {
      final range = preloadRange(
        currentIndex: 2,
        urlCount: 10,
        preloadCount: 3,
      )!;
      expect(range.start, 2);
      expect(range.end, 5);
    });

    test('clamps the end at the last page', () {
      final range = preloadRange(
        currentIndex: 8,
        urlCount: 10,
        preloadCount: 5,
      )!;
      expect(range.start, 8);
      expect(range.end, 9);
    });

    test('clamps an out-of-range current index', () {
      final range = preloadRange(
        currentIndex: 12,
        urlCount: 10,
        preloadCount: 2,
      )!;
      expect(range.start, 9);
      expect(range.end, 9);
    });

    test('clamps a negative current index', () {
      final range = preloadRange(
        currentIndex: -3,
        urlCount: 10,
        preloadCount: 2,
      )!;
      expect(range.start, 0);
      expect(range.end, 0);
    });

    test('zero preload count stays on the current page', () {
      final range = preloadRange(
        currentIndex: 4,
        urlCount: 10,
        preloadCount: 0,
      )!;
      expect(range.start, 4);
      expect(range.end, 4);
    });

    test('negative preload count stays on the current page', () {
      final range = preloadRange(
        currentIndex: 4,
        urlCount: 10,
        preloadCount: -2,
      )!;
      expect(range.start, 4);
      expect(range.end, 4);
    });
  });

  group('ReaderPageVisibility.hidden', () {
    test('marks the page as not visible', () {
      final hidden = ReaderPageVisibility.hidden(3, tick: 7);
      expect(hidden.index, 3);
      expect(hidden.tick, 7);
      expect(hidden.visiblePixels, 0);
      expect(hidden.centerDistance, double.infinity);
      expect(hidden.containsViewportCenter, isFalse);
    });
  });

  group('sync debounce', () {
    test('progress sync debounce is one second', () {
      expect(readerProgressSyncDebounce, const Duration(seconds: 1));
    });
  });
}
