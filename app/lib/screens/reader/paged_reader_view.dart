import 'package:flutter/material.dart';

import '../../widgets/loading_indicator.dart';

/// 点击翻页模式的单页阅读视图。
///
/// - PageView 每屏一页，图片 `BoxFit.contain`（横屏自然按高度适配）。
/// - 点击左/右 30% 区域翻上一页/下一页（LTR），中间区域呼出/隐藏工具栏。
/// - 保留左右滑动手势与长按下载。
/// 进度页码即 image_index，由父级通过 [onPageChanged] 维护；外部页码变化
/// （如阅读进度恢复、模式切换）通过 [targetIndex] 驱动跳页。
class PagedReaderView extends StatefulWidget {
  final List<String> imageUrls;
  final int targetIndex;
  final ImageProvider Function(String url) imageProviderFor;
  final ValueChanged<int> onPageChanged;
  final void Function(String url, int index) onLongPressPage;
  final VoidCallback onToggleToolbar;
  final VoidCallback onClearBackoff;
  final String loadingMessage;
  final String failedMessage;

  const PagedReaderView({
    super.key,
    required this.imageUrls,
    required this.targetIndex,
    required this.imageProviderFor,
    required this.onPageChanged,
    required this.onLongPressPage,
    required this.onToggleToolbar,
    required this.onClearBackoff,
    required this.loadingMessage,
    required this.failedMessage,
  });

  @override
  State<PagedReaderView> createState() => _PagedReaderViewState();
}

class _PagedReaderViewState extends State<PagedReaderView> {
  late final PageController _controller;
  late int _currentPage;
  final Map<String, int> _retryCounts = {};
  int? _animationTarget;

  @override
  void initState() {
    super.initState();
    _currentPage = _clampPage(widget.targetIndex);
    _controller = PageController(initialPage: _currentPage);
  }

  /// 空章节时没有可显示页，统一按第 0 页处理（与滚动模式的空列表防御一致）。
  int _clampPage(int page) {
    if (widget.imageUrls.isEmpty) return 0;
    return page.clamp(0, widget.imageUrls.length - 1);
  }

  @override
  void didUpdateWidget(covariant PagedReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetIndex != _currentPage && widget.imageUrls.isNotEmpty) {
      final target = _clampPage(widget.targetIndex);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        if (target == _currentPage) return;
        _currentPage = target;
        _animationTarget = null;
        _controller.jumpToPage(target);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 点击翻页的基准页：动画进行中以动画目标为准，避免 150ms 动画内
  /// 连续点击仍基于旧页码计算而少翻一页。基准在页面落定（onPageChanged）
  /// 或外部跳页时清除。
  int get _tapBasePage => _animationTarget ?? _currentPage;

  void _goToPage(int page) {
    if (widget.imageUrls.isEmpty) return;
    final target = _clampPage(page);
    if (target == _tapBasePage) return;
    _animationTarget = target;
    _controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  void _handleTapUp(TapUpDetails details, double width) {
    if (width <= 0) return;
    final fraction = details.localPosition.dx / width;
    if (fraction < 0.3) {
      _goToPage(_tapBasePage - 1);
    } else if (fraction > 0.7) {
      _goToPage(_tapBasePage + 1);
    } else {
      widget.onToggleToolbar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapUp: (details) => _handleTapUp(details, constraints.maxWidth),
          behavior: HitTestBehavior.opaque,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              _currentPage = index;
              // 页面落定（或动画被打断后落到别的页）后，不再以旧动画目标为基准。
              _animationTarget = null;
              widget.onPageChanged(index);
            },
            itemBuilder: (context, index) {
              final url = widget.imageUrls[index];
              final retryCount = _retryCounts[url] ?? 0;
              return GestureDetector(
                onLongPress: () => widget.onLongPressPage(url, index),
                behavior: HitTestBehavior.translucent,
                child: Image(
                  key: ValueKey('paged_image_${url}_$retryCount'),
                  image: widget.imageProviderFor(url),
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded || frame != null) {
                          return child;
                        }
                        return ImagePlaceholder(message: widget.loadingMessage);
                      },
                  errorBuilder: (_, _, _) => ImageErrorPlaceholder(
                    message: widget.failedMessage,
                    onRetry: () {
                      widget.onClearBackoff();
                      setState(() {
                        _retryCounts[url] = retryCount + 1;
                      });
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
