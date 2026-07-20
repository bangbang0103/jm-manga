import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/theme/app_shadows.dart';
import '../providers/account_provider.dart';
import '../providers/album_providers.dart';
import '../providers/app_sync_provider.dart';
import '../providers/app_update_provider.dart';
import '../providers/library_signal_provider.dart';
import '../utils/platform_utils.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'rankings_screen.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  final int libraryTab;

  const MainScreen({super.key, this.initialIndex = 0, this.libraryTab = 0});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late int _currentIndex;
  late final Set<int> _loadedIndexes;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadedIndexes = {_currentIndex};
    _initUpdateCheck();
  }

  void _initUpdateCheck() {
    // 更新检查面向 Android APK 发布包，桌面端跳过。
    if (isDesktopPlatform) return;
    unawaited(_checkForUpdates());
  }

  Future<void> _checkForUpdates() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final notifier = ref.read(appUpdateProvider.notifier);
    notifier.setCurrentVersion(packageInfo.version);
    await notifier.checkForUpdates(silent: true);
  }

  @override
  void didUpdateWidget(covariant MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex &&
        widget.initialIndex != _currentIndex) {
      setState(() {
        _currentIndex = widget.initialIndex;
        _loadedIndexes.add(_currentIndex);
      });
    }
  }

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
      _loadedIndexes.add(index);
    });
    if (index == 2) {
      ref.read(librarySignalProvider.notifier).state++;
    }
  }

  Future<bool> _confirmExit() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.exitAppTitle),
        content: Text(l10n.exitAppBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.actionExit),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen(selectedAccountProvider, (previous, next) {
      if (next == null || next.isAnonymous) return;
      final lastSync = ref.read(lastAccountSwitchSyncProvider);
      final now = DateTime.now();
      if (lastSync != null && now.difference(lastSync).inSeconds < 60) return;
      ref.read(lastAccountSwitchSyncProvider.notifier).state = now;
      unawaited(
        ref
            .read(favoritesProvider.notifier)
            .sync()
            .catchError((_) => {'synced': false}),
      );
    });

    final pages = <Widget>[
      _loadedIndexes.contains(0) ? const HomeScreen() : const SizedBox.shrink(),
      _loadedIndexes.contains(1)
          ? const RankingsScreen()
          : const SizedBox.shrink(),
      _loadedIndexes.contains(2)
          ? LibraryScreen(initialTab: widget.libraryTab)
          : const SizedBox.shrink(),
      _loadedIndexes.contains(3)
          ? const SettingsScreen()
          : const SizedBox.shrink(),
    ];

    // 宽屏（横屏/桌面窗口）使用 NavigationRail，窄屏保持底部导航。
    final isWide = MediaQuery.sizeOf(context).width >= 840;

    final scaffold = Scaffold(
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onTap,
                  labelType: NavigationRailLabelType.all,
                  // 与底部导航一致：不用指示器，仅靠图标激活态与颜色表达选中，
                  // 切换时带淡入淡出过渡。
                  useIndicator: false,
                  destinations: [
                    for (final (index, item) in [
                      (Icons.home_outlined, Icons.home, l10n.navHome),
                      (
                        Icons.trending_up_outlined,
                        Icons.trending_up,
                        l10n.navRankings,
                      ),
                      (
                        Icons.library_books_outlined,
                        Icons.library_books,
                        l10n.navLibrary,
                      ),
                      (
                        Icons.settings_outlined,
                        Icons.settings,
                        l10n.navSettings,
                      ),
                    ].indexed)
                      NavigationRailDestination(
                        icon: _AnimatedNavIcon(
                          outlinedIcon: item.$1,
                          filledIcon: item.$2,
                          selected: _currentIndex == index,
                        ),
                        label: _AnimatedNavLabel(
                          text: item.$3,
                          selected: _currentIndex == index,
                        ),
                      ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: IndexedStack(index: _currentIndex, children: pages),
                ),
              ],
            )
          : IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: isWide
          ? null
          : Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                boxShadow: AppShadows.bottomBar,
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: _onTap,
                type: BottomNavigationBarType.fixed,
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home_outlined),
                    activeIcon: const Icon(Icons.home),
                    label: l10n.navHome,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.trending_up_outlined),
                    activeIcon: const Icon(Icons.trending_up),
                    label: l10n.navRankings,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.library_books_outlined),
                    activeIcon: const Icon(Icons.library_books),
                    label: l10n.navLibrary,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.settings_outlined),
                    activeIcon: const Icon(Icons.settings),
                    label: l10n.navSettings,
                  ),
                ],
              ),
            ),
    );

    // 桌面端没有系统返回键，退出确认只适用于移动端。
    if (isDesktopPlatform) {
      return scaffold;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _confirmExit();
        if (shouldExit && mounted) {
          await SystemNavigator.pop();
        }
      },
      child: scaffold,
    );
  }
}

/// 宽屏导航的图标：选中态切换时淡入淡出，对齐底部导航的图标激活动效。
class _AnimatedNavIcon extends StatelessWidget {
  final IconData outlinedIcon;
  final IconData filledIcon;
  final bool selected;

  const _AnimatedNavIcon({
    required this.outlinedIcon,
    required this.filledIcon,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Icon(
        selected ? filledIcon : outlinedIcon,
        key: ValueKey(selected),
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
    );
  }
}

/// 宽屏导航的标签：字体与底部导航一致（labelMedium），颜色随选中态过渡。
class _AnimatedNavLabel extends StatelessWidget {
  final String text;
  final bool selected;

  const _AnimatedNavLabel({required this.text, required this.selected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = theme.textTheme.labelMedium ?? const TextStyle();
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 200),
      style: base.copyWith(
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      child: Text(text),
    );
  }
}
