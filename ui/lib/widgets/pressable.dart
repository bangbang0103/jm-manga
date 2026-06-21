import 'package:flutter/material.dart';

/// 按下时轻微缩放的反馈包装器。
/// 自动遵守系统“减弱动态效果”设置。
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressScale;
  final Duration duration;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressScale = 0.97,
    this.duration = const Duration(milliseconds: 120),
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: widget.pressScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _animationsDisabled {
    return MediaQuery.of(context).disableAnimations;
  }

  void _onTapDown(_) {
    if (widget.onTap == null || _animationsDisabled) return;
    _controller.forward();
  }

  void _onTapUp(_) {
    if (_animationsDisabled) return;
    _controller.reverse();
  }

  void _onTapCancel() {
    if (_animationsDisabled) return;
    _controller.reverse();
  }

  void _onTap() {
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap == null ? null : _onTap,
      behavior: HitTestBehavior.translucent,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(scale: _scale.value, child: child);
        },
        child: widget.child,
      ),
    );
  }
}
