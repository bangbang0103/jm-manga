import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/screens/reader/paged_reader_view.dart';

import '../pending_image_provider.dart';
import '../testable_app.dart';

void main() {
  group('PagedReaderView', () {
    const urls = ['u0', 'u1', 'u2', 'u3', 'u4'];

    Widget buildView({
      List<String> imageUrls = urls,
      int targetIndex = 0,
      ValueChanged<int>? onPageChanged,
      void Function(String url, int index)? onLongPressPage,
      VoidCallback? onToggleToolbar,
    }) {
      return testable(
        PagedReaderView(
          imageUrls: imageUrls,
          targetIndex: targetIndex,
          imageProviderFor: (_) => const PendingImageProvider(),
          onPageChanged: onPageChanged ?? (_) {},
          onLongPressPage: onLongPressPage ?? (_, _) {},
          onToggleToolbar: onToggleToolbar ?? () {},
          onClearBackoff: () {},
          loadingMessage: 'Loading',
          failedMessage: 'Failed',
        ),
      );
    }

    double currentPage(WidgetTester tester) =>
        tester.widget<PageView>(find.byType(PageView)).controller!.page!;

    testWidgets('starts at targetIndex', (WidgetTester tester) async {
      await tester.pumpWidget(buildView(targetIndex: 2));
      await tester.pump();

      expect(currentPage(tester), 2);
    });

    testWidgets('tap zones navigate pages and toggle toolbar', (
      WidgetTester tester,
    ) async {
      final pages = <int>[];
      var toggled = false;
      await tester.pumpWidget(
        buildView(
          onPageChanged: pages.add,
          onToggleToolbar: () => toggled = true,
        ),
      );
      await tester.pump();

      // 右侧 30%：下一页。tap 手势在下一帧手势竞技场结算时才触发，
      // 需要先 pump 一帧启动翻页动画，再推进动画时长。
      await tester.tapAt(const Offset(760, 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(pages, [1]);

      // 左侧 30%：上一页。
      await tester.tapAt(const Offset(40, 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(pages, [1, 0]);

      // 中间区域：呼出/隐藏工具栏，不翻页。
      await tester.tapAt(const Offset(400, 300));
      await tester.pump();
      expect(toggled, isTrue);
      expect(pages, [1, 0]);
    });

    testWidgets('rapid taps during page animation do not lose pages', (
      WidgetTester tester,
    ) async {
      final pages = <int>[];
      await tester.pumpWidget(buildView(onPageChanged: pages.add));
      await tester.pump();

      // 150ms 翻页动画未结束时再次点击，应以动画目标页为基准继续翻页。
      await tester.tapAt(const Offset(760, 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(const Offset(760, 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(pages, isNotEmpty);
      expect(pages.last, 2);
      expect(currentPage(tester), 2);
    });

    testWidgets('swipe changes page', (WidgetTester tester) async {
      final pages = <int>[];
      await tester.pumpWidget(buildView(onPageChanged: pages.add));
      await tester.pump();

      await tester.fling(find.byType(PageView), const Offset(-300, 0), 800);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(pages, isNotEmpty);
      expect(pages.last, 1);
    });

    testWidgets('long press reports url and index', (
      WidgetTester tester,
    ) async {
      String? pressedUrl;
      int? pressedIndex;
      await tester.pumpWidget(
        buildView(
          onLongPressPage: (url, index) {
            pressedUrl = url;
            pressedIndex = index;
          },
        ),
      );
      await tester.pump();

      await tester.longPressAt(const Offset(400, 300));

      expect(pressedUrl, 'u0');
      expect(pressedIndex, 0);
    });

    testWidgets('empty chapter renders and ignores page taps', (
      WidgetTester tester,
    ) async {
      final pages = <int>[];
      var toggled = false;
      await tester.pumpWidget(
        buildView(
          imageUrls: const [],
          onPageChanged: pages.add,
          onToggleToolbar: () => toggled = true,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      // 空列表时点击翻页区域不抛异常、不报页码。
      await tester.tapAt(const Offset(760, 300));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(pages, isEmpty);

      // 中间区域呼出工具栏仍然可用。
      await tester.tapAt(const Offset(400, 300));
      await tester.pump();
      expect(toggled, isTrue);
    });
  });
}
