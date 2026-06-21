import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 用于在 MainScreen 点击底部 Library 导航时通知 LibraryScreen 刷新当前 Tab。
final librarySignalProvider = StateProvider<int>((ref) => 0);
