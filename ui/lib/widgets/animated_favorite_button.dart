import 'package:flutter/material.dart';

/// 收藏按钮，切换时带心跳脉冲动画。
/// 自动遵守系统“减弱动态效果”设置。
class AnimatedFavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback? onPressed;
  final double size;
  final EdgeInsets padding;
  final Color? color;
  final Color? inactiveColor;

  const AnimatedFavoriteButton({
    super.key,
    required this.isFavorite,
    this.onPressed,
    this.size = 24,
    this.padding = const EdgeInsets.all(8),
    this.color,
    this.inactiveColor,
  });

  @override
  State<AnimatedFavoriteButton> createState() => _AnimatedFavoriteButtonState();
}

class _AnimatedFavoriteButtonState extends State<AnimatedFavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  bool _previousFavorite = false;

  @override
  void initState() {
    super.initState();
    _previousFavorite = widget.isFavorite;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 1.0,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.18, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant AnimatedFavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorite != _previousFavorite) {
      _previousFavorite = widget.isFavorite;
      if (!_animationsDisabled) {
        _controller.forward(from: 0);
      }
    }
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
    if (widget.onPressed == null || _animationsDisabled) return;
    _controller.animateTo(0.9, duration: const Duration(milliseconds: 80));
  }

  void _onTapUp(_) {
    if (_animationsDisabled) return;
    _controller.animateTo(1.0, duration: const Duration(milliseconds: 120));
  }

  void _onTapCancel() {
    if (_animationsDisabled) return;
    _controller.animateTo(1.0, duration: const Duration(milliseconds: 120));
  }

  void _onTap() {
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isFavorite
        ? (widget.color ?? Theme.of(context).colorScheme.secondary)
        : (widget.inactiveColor ?? Theme.of(context).colorScheme.onSurfaceVariant);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed == null ? null : _onTap,
      behavior: HitTestBehavior.translucent,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(scale: _scale.value, child: child);
        },
        child: Padding(
          padding: widget.padding,
          child: Icon(
            widget.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: color,
            size: widget.size,
          ),
        ),
      ),
    );
  }
}
