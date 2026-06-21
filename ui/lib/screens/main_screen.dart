import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_shadows.dart';
import '../providers/account_provider.dart';
import '../providers/album_providers.dart';
import '../providers/app_sync_provider.dart';
import '../providers/library_signal_provider.dart';
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
        ref.read(favoritesProvider.notifier).sync().catchError((_) => false),
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

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: Container(
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
  }
}
