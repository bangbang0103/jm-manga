import 'package:flutter/material.dart';

/// 一个遵循系统“减弱动态效果”设置的进入动画包装。
///
/// 通过 [animation] 的 value 控制透明度和缩放；通常与父级统一动画 +
/// [Interval] 组合出 stagger 效果。如果系统要求减少动画，则直接显示子元素。
class AnimatedItem extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  final double beginScale;

  const AnimatedItem({
    super.key,
    required this.animation,
    required this.child,
    this.beginScale = 0.94,
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return child;
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = animation.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: beginScale + (1.0 - beginScale) * value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
