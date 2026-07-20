import 'package:flutter/material.dart';

/// 宽屏下把内容限制在 [maxWidth] 并顶部居中，窄屏下等价于原样填充。
///
/// 用于设置、日志、详情等表单/文本页，避免在横屏或桌面窗口中
/// 内容被拉伸到难以阅读的宽度。
class MaxWidthCenter extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const MaxWidthCenter({super.key, this.maxWidth = 840, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
