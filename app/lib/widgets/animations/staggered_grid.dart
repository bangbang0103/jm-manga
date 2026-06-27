import 'package:flutter/material.dart';

import 'animated_item.dart';

/// 带统一 stagger 进入动画的 GridView。
///
/// 当 [items] 从空变为非空时会触发一次进入动画；后续数据刷新、加载更多
/// 不会重新触发，避免滚动时重复动画造成疲劳。
class StaggeredGrid<T> extends StatefulWidget {
  final List<T> items;
  final SliverGridDelegate gridDelegate;
  final EdgeInsetsGeometry padding;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final ScrollPhysics physics;
  final Widget? loadingIndicator;
  final Duration duration;
  final Duration staggerDelay;
  final int maxStaggerItems;

  const StaggeredGrid({
    super.key,
    required this.items,
    required this.gridDelegate,
    required this.itemBuilder,
    this.padding = const EdgeInsets.all(16),
    this.physics = const AlwaysScrollableScrollPhysics(),
    this.loadingIndicator,
    this.duration = const Duration(milliseconds: 350),
    this.staggerDelay = const Duration(milliseconds: 45),
    this.maxStaggerItems = 20,
  });

  @override
  State<StaggeredGrid<T>> createState() => _StaggeredGridState<T>();
}

class _StaggeredGridState<T> extends State<StaggeredGrid<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _wasEmpty = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.items.isEmpty ? 0.0 : 1.0,
    );
    _wasEmpty = widget.items.isEmpty;
    if (widget.items.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _triggerAnimation());
    }
  }

  @override
  void didUpdateWidget(covariant StaggeredGrid<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isEmpty = widget.items.isEmpty;
    if (isEmpty) {
      _controller.value = 0.0;
      _wasEmpty = true;
      return;
    }

    if (_wasEmpty) {
      _wasEmpty = false;
      _triggerAnimation();
    }
  }

  void _triggerAnimation() {
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1.0;
      return;
    }
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _animationFor(int index) {
    final delayMs =
        widget.staggerDelay.inMilliseconds *
        index.clamp(0, widget.maxStaggerItems);
    final totalMs = widget.duration.inMilliseconds;
    final begin = (delayMs / totalMs).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, 1.0, curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemCount =
        widget.items.length + (widget.loadingIndicator != null ? 1 : 0);

    return GridView.builder(
      physics: widget.physics,
      padding: widget.padding,
      gridDelegate: widget.gridDelegate,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == widget.items.length && widget.loadingIndicator != null) {
          return widget.loadingIndicator!;
        }
        final item = widget.items[index];
        return AnimatedItem(
          animation: _animationFor(index),
          child: widget.itemBuilder(context, item, index),
        );
      },
    );
  }
}
