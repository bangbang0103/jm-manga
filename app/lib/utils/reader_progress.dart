/// 阅读器进度相关的纯逻辑，从 reader_screen.dart 抽出以便单元测试。
/// 这里的函数不依赖 BuildContext / Widget，行为与原实现保持一致。
library;

/// 单页图片相对视口的可见性快照。
class ReaderPageVisibility {
  final int index;
  final int tick;
  final double visiblePixels;
  final double centerDistance;
  final bool containsViewportCenter;

  const ReaderPageVisibility({
    required this.index,
    required this.tick,
    required this.visiblePixels,
    required this.centerDistance,
    required this.containsViewportCenter,
  });

  /// 页面完全不可见（未挂载、视口未就绪等）时的占位快照。
  factory ReaderPageVisibility.hidden(int index, {required int tick}) {
    return ReaderPageVisibility(
      index: index,
      tick: tick,
      visiblePixels: 0,
      centerDistance: double.infinity,
      containsViewportCenter: false,
    );
  }
}

/// resume 跳帧的最大尝试次数：目标页尚未构建时按估算偏移逐帧逼近。
const int readerResumeMaxAttempts = 20;

/// 进度同步的防抖时长：连续翻页时只在停稳后 flush 一次。
const Duration readerProgressSyncDebounce = Duration(seconds: 1);

/// 页码是否落在 [0, pageCount) 有效范围内。
bool isValidPageIndex(int index, int pageCount) =>
    pageCount > 0 && index >= 0 && index < pageCount;

/// 断点续读的目标页：pageCount 非法时不续读（返回 null），
/// 否则把已保存的 imageIndex 钳制到 [0, pageCount - 1]。
int? resumeTargetIndex(int imageIndex, int pageCount) {
  if (pageCount <= 0) return null;
  return imageIndex.clamp(0, pageCount - 1).toInt();
}

/// resume 目标 index 是否需要跳帧：第 0 页本来就是起始页，无需跳转；
/// 越界 index 直接放弃。
bool isResumableIndex(int index, int itemCount) =>
    index > 0 && index < itemCount;

/// resume 跳帧次数是否仍未达到上限。
bool canAttemptResumeJump(int attempts) => attempts < readerResumeMaxAttempts;

/// 计算翻页后的当前页：pageCount 非法或钳制后与 currentIndex 相同
/// （页码没有变化，无需触发进度保存）时返回 null。
int? clampedPageChange(
  int index, {
  required int currentIndex,
  required int pageCount,
}) {
  if (pageCount <= 0) return null;
  final safeIndex = index.clamp(0, pageCount - 1).toInt();
  if (safeIndex == currentIndex) return null;
  return safeIndex;
}

/// 是否已翻到最后一页（视为读完）。
bool isFinishedPage(int index, int pageCount) =>
    pageCount > 0 && index >= pageCount - 1;

/// 把一页的可见性快照写入 [visiblePages]：可见像素 <= 0 视为离开视口。
void updateVisiblePages(
  Map<int, ReaderPageVisibility> visiblePages,
  ReaderPageVisibility visibility,
) {
  if (visibility.visiblePixels <= 0) {
    visiblePages.remove(visibility.index);
  } else {
    visiblePages[visibility.index] = visibility;
  }
}

/// 从各页的可见性快照计算当前页号。
///
/// 只统计本轮 tick 且可见像素 > 0 的有效页；优先取包含视口中心的页
/// （多页重叠时取中心距离最近的），否则取可见像素最多的页，
/// 再依次按中心距离、页码兜底。没有可见页时返回 null。
int? currentIndexFromVisibility(
  Iterable<ReaderPageVisibility> pages, {
  required int currentTick,
  required int pageCount,
}) {
  final visible = pages
      .where(
        (v) =>
            v.tick == currentTick &&
            isValidPageIndex(v.index, pageCount) &&
            v.visiblePixels > 0,
      )
      .toList();
  if (visible.isEmpty) return null;

  visible.sort((a, b) {
    if (a.containsViewportCenter != b.containsViewportCenter) {
      return a.containsViewportCenter ? -1 : 1;
    }
    if (a.containsViewportCenter && b.containsViewportCenter) {
      final centerCompare = a.centerDistance.compareTo(b.centerDistance);
      if (centerCompare != 0) return centerCompare;
    } else {
      final visibleCompare = b.visiblePixels.compareTo(a.visiblePixels);
      if (visibleCompare != 0) return visibleCompare;
      final centerCompare = a.centerDistance.compareTo(b.centerDistance);
      if (centerCompare != 0) return centerCompare;
    }
    return a.index.compareTo(b.index);
  });

  return visible.first.index;
}

/// 按视口宽度与已加载图片的真实宽高比，估算每页在列表中的高度
/// （图片按宽度撑满，高度 = 视口宽度 / 宽高比）。
/// 视口宽度非法时返回 null，调用方应保留上一次的估算。
({double fallbackExtent, List<double> itemExtents})? estimateItemExtents({
  required List<String> urls,
  required double viewportWidth,
  required double fallbackAspectRatio,
  required Map<String, double> imageAspectRatios,
}) {
  if (viewportWidth <= 0) return null;
  return (
    fallbackExtent: viewportWidth / fallbackAspectRatio,
    itemExtents: [
      for (final url in urls)
        viewportWidth / (imageAspectRatios[url] ?? fallbackAspectRatio),
    ],
  );
}

/// 估算第 [index] 页顶部的滚动偏移：有逐页高度估算时逐项求和，
/// 否则按兜底高度乘以页数。
double estimatedOffsetForIndex(
  int index, {
  required List<double> itemExtents,
  required double fallbackExtent,
}) {
  if (index <= 0) return 0;
  if (itemExtents.isEmpty) {
    return index * fallbackExtent;
  }

  var offset = 0.0;
  final safeIndex = index.clamp(0, itemExtents.length).toInt();
  for (var i = 0; i < safeIndex; i++) {
    offset += itemExtents[i];
  }
  return offset;
}

/// 预加载的页码区间（含端点）：从当前页起向后 [preloadCount] 页，
/// 两端都钳制到 [0, urlCount - 1]；没有图片时返回 null。
({int start, int end})? preloadRange({
  required int currentIndex,
  required int urlCount,
  required int preloadCount,
}) {
  if (urlCount <= 0) return null;
  final start = currentIndex.clamp(0, urlCount - 1).toInt();
  final end = preloadCount <= 0
      ? start
      : (currentIndex + preloadCount).clamp(0, urlCount - 1).toInt();
  return (start: start, end: end);
}
