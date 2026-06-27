import 'package:flutter/material.dart';

/// 受控的投影集合。
///
/// 设计系统以 tonal layering 为主，阴影只少量用于“浮在内容之上”的元素，
/// 保持整体扁平、温暖的气质。
class AppShadows {
  /// 底部条向上投射的微弱阴影（底部导航、底部悬浮栏）。
  static List<BoxShadow> get bottomBar => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, -2),
        ),
      ];
}
