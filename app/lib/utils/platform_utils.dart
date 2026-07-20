import 'package:flutter/foundation.dart';

/// 是否为桌面平台（Windows / macOS / Linux）。Web 不算桌面。
bool get isDesktopPlatform {
  if (kIsWeb) return false;
  return switch (defaultTargetPlatform) {
    TargetPlatform.windows ||
    TargetPlatform.macOS ||
    TargetPlatform.linux => true,
    _ => false,
  };
}
