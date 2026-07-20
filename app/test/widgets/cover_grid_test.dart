import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/providers/config_provider.dart';
import 'package:jm_manga/widgets/animations/staggered_grid.dart';

/// 用 SliverGridDelegate 的布局结果计算给定可用宽度下的列数。
int columnCount(SliverGridDelegate delegate, double width) {
  final layout = delegate.getLayout(
    SliverConstraints(
      axisDirection: AxisDirection.down,
      growthDirection: GrowthDirection.forward,
      userScrollDirection: ScrollDirection.idle,
      scrollOffset: 0,
      precedingScrollExtent: 0,
      overlap: 0,
      remainingPaintExtent: 600,
      crossAxisExtent: width,
      crossAxisDirection: AxisDirection.right,
      viewportMainAxisExtent: 600,
      remainingCacheExtent: 0,
      cacheOrigin: 0,
    ),
  );
  return (layout as SliverGridRegularTileLayout).crossAxisCount;
}

void main() {
  group('coverGridDelegate', () {
    test('density max extents', () {
      expect(GridDensity.compact.maxCrossAxisExtent, 100);
      expect(GridDensity.standard.maxCrossAxisExtent, 150);
      expect(GridDensity.loose.maxCrossAxisExtent, 240);
    });

    test('column counts match legacy phone layout', () {
      // 390dp 手机：网格 padding 16×2 后可用宽度约 358。
      // 与旧版固定列数一致：compact ≈ 4 列、standard ≈ 3 列（旧默认）、loose ≈ 2 列。
      expect(columnCount(coverGridDelegate(GridDensity.compact), 358), 4);
      expect(columnCount(coverGridDelegate(GridDensity.standard), 358), 3);
      expect(columnCount(coverGridDelegate(GridDensity.loose), 358), 2);
    });

    test('wider screens fit more columns', () {
      expect(
        columnCount(coverGridDelegate(GridDensity.standard), 1024),
        greaterThan(3),
      );
    });
  });
}
