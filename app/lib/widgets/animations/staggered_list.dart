import 'package:flutter/material.dart';

import 'animated_item.dart';

/// 带统一 stagger 进入动画的 ListView。
///
/// 行为与 [StaggeredGrid] 一致：仅在 [items] 从空变为非空时触发一次进入动画。
class StaggeredList<T> extends StatefulWidget {
  final List<T> items;
  final Axis scrollDirection;
  final EdgeInsetsGeometry padding;
  final double? separatorExtent;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final ScrollPhysics physics;
  final Duration duration;
  final Duration staggerDelay;
  final int maxStaggerItems;

  const StaggeredList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.scrollDirection = Axis.vertical,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.separatorExtent,
    this.physics = const AlwaysScrollableScrollPhysics(),
    this.duration = const Duration(milliseconds: 350),
    this.staggerDelay = const Duration(milliseconds: 45),
    this.maxStaggerItems = 15,
  });

  @override
  State<StaggeredList<T>> createState() => _StaggeredListState<T>();
}

class _StaggeredListState<T> extends State<StaggeredList<T>>
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
  void didUpdateWidget(covariant StaggeredList<T> oldWidget) {
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
    final itemCount = widget.items.length;
    final separator = widget.separatorExtent;

    return ListView.separated(
      physics: widget.physics,
      scrollDirection: widget.scrollDirection,
      padding: widget.padding,
      itemCount: itemCount,
      separatorBuilder:
          separator == null
              ? (_, _) => const SizedBox.shrink()
              : (_, _) =>
                  SizedBox(
                    width:
                        widget.scrollDirection == Axis.horizontal
                            ? separator
                            : 0,
                    height:
                        widget.scrollDirection == Axis.vertical
                            ? separator
                            : 0,
                  ),
      itemBuilder: (context, index) {
        final item = widget.items[index];
        return AnimatedItem(
          animation: _animationFor(index),
          child: widget.itemBuilder(context, item, index),
        );
      },
    );
  }
}
