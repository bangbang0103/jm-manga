import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 记录上一次“刷新登录并同步收藏”的时间，用于防抖。
final lastLoginRefreshSyncProvider = StateProvider<DateTime?>((ref) => null);

/// 记录上一次“切换账号后自动同步收藏”的时间，用于防抖。
final lastAccountSwitchSyncProvider = StateProvider<DateTime?>((ref) => null);
