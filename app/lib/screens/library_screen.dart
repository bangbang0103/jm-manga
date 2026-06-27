import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/loading_indicator.dart';

import '../models/album.dart';
import '../providers/account_provider.dart';
import '../providers/album_providers.dart';
import '../providers/config_provider.dart';
import '../providers/library_signal_provider.dart';
import '../providers/repository_provider.dart';
import '../utils/error_mapper.dart';
import '../utils/favorite_action.dart';
import '../utils/top_toast.dart';
import '../widgets/animations/staggered_grid.dart';
import '../widgets/manga_cover_card.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const LibraryScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab &&
        widget.initialTab != _tabController.index) {
      _tabController.index = widget.initialTab;
    }
  }

  void _onTabTapped(int index) {
    setState(() {});
    if (index == 0) {
      unawaited(ref.read(favoritesProvider.notifier).refresh());
    } else {
      unawaited(ref.refresh(readingProgressProvider.future));
    }
  }

  Future<void> _syncFavoritesWithFeedback() async {
    if (_isSyncing) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSyncing = true);
    try {
      final result = await ref.read(favoritesProvider.notifier).sync();
      final failed = result['failed'];
      if (mounted) {
        if (failed is List && failed.isNotEmpty) {
          TopToast.show(
            context,
            l10n.favoriteSyncPartialFailure(failed.length),
            type: TopToastType.info,
          );
        } else {
          TopToast.show(
            context,
            l10n.favoriteSyncSuccess,
            type: TopToastType.success,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        TopToast.show(
          context,
          mapErrorToUserMessage(e, l10n),
          type: TopToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final account = ref.watch(selectedAccountProvider);
    final hasAccount = account != null && !account.isAnonymous;

    ref.listen(librarySignalProvider, (previous, current) {
      _onTabTapped(_tabController.index);
    });

    final favorites = ref.watch(favoritesProvider);
    final reading = ref.watch(readingProgressProvider);
    final favoritesNotifier = ref.read(favoritesProvider.notifier);
    final repo = ref.read(apiRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.libraryTitle),
        bottom: TabBar(
          controller: _tabController,
          onTap: _onTabTapped,
          tabs: [
            Tab(text: l10n.tabFavorite),
            Tab(text: l10n.tabRecentRead),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_tabController.index == 0 && hasAccount)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: l10n.favoriteSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: TextButton(
                    onPressed: _isSyncing ? null : _syncFavoritesWithFeedback,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text(
                      _isSyncing ? l10n.favoriteSyncing : l10n.favoriteSyncNow,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) => favoritesNotifier.search(value),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAlbumGrid(
                  asyncItems: favorites,
                  onRefresh: () =>
                      ref.read(favoritesProvider.notifier).refresh(),
                  onLoadMore: hasAccount ? favoritesNotifier.loadMore : null,
                  coverUrlFor: (item) =>
                      item.coverUrl ?? repo.coverUrl(item.albumId),
                  titleFor: (item) => item.title,
                  routeFor: (item) => '/album/${item.albumId}',
                  albumIdFor: (item) => item.albumId,
                  itemForFavorite: (item) => item,
                  emptyMessage: l10n.favoriteEmpty,
                  emptyAction: hasAccount
                      ? (
                          label: l10n.favoriteSyncNow,
                          onPressed: _syncFavoritesWithFeedback,
                        )
                      : null,
                ),
                _buildAlbumGrid(
                  asyncItems: reading,
                  onRefresh: () => ref.refresh(readingProgressProvider.future),
                  coverUrlFor: (progress) => repo.coverUrl(progress.albumId),
                  titleFor: (progress) =>
                      progress.title ?? 'Album ${progress.albumId}',
                  badgeTextFor: (progress) => progress.localizedBadgeText(l10n),
                  albumIdFor: (progress) => progress.albumId,
                  routeFor: (progress) => '/album/${progress.albumId}',
                  itemForFavorite: (progress) => AlbumItem(
                    albumId: progress.albumId,
                    title: progress.title ?? 'Album ${progress.albumId}',
                    tags: const [],
                  ),
                  emptyMessage: l10n.recentEmpty,
                  emptyAction: (
                    label: l10n.recentBrowseManga,
                    onPressed: () => context.go('/?tab=home'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumGrid<T>({
    required AsyncValue<List<T>> asyncItems,
    required Future<void> Function() onRefresh,
    Future<void> Function()? onLoadMore,
    required String Function(T item) coverUrlFor,
    required String Function(T item) titleFor,
    required String Function(T item) routeFor,
    String Function(T item)? badgeTextFor,
    String Function(T item)? albumIdFor,
    AlbumItem Function(T item)? itemForFavorite,
    required String emptyMessage,
    ({String label, VoidCallback onPressed})? emptyAction,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final favoriteIdsAsync = ref.watch(favoriteAlbumIdsProvider);
    final repo = ref.read(apiRepositoryProvider);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: asyncItems.when(
        data: (items) {
          if (items.isEmpty) {
            return LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(emptyMessage),
                        if (emptyAction != null) ...[
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: emptyAction.onPressed,
                            child: Text(emptyAction.label),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          final gridColumns = ref.watch(configProvider).gridColumns;
          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (onLoadMore != null &&
                  notification is ScrollEndNotification &&
                  notification.metrics.extentAfter < 200) {
                onLoadMore();
              }
              return false;
            },
            child: StaggeredGrid<T>(
              items: items,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridColumns,
                childAspectRatio: 2 / 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
              ),
              staggerDelay: const Duration(milliseconds: 35),
              itemBuilder: (context, item, index) {
                final albumId = albumIdFor?.call(item);
                final isFavorite =
                    albumId != null &&
                    (favoriteIdsAsync.valueOrNull?.contains(albumId) ?? false);
                return MangaCoverCard(
                  title: titleFor(item),
                  badgeText: badgeTextFor?.call(item),
                  imageProvider: repo.imageProvider(coverUrlFor(item)),
                  isFavorite: isFavorite,
                  onTap: () => context.push(routeFor(item)),
                  onFavorite: albumId != null
                      ? () => toggleFavoriteAction(
                          context,
                          ref,
                          albumId: albumId,
                          item: itemForFavorite?.call(item),
                        )
                      : null,
                );
              },
            ),
          );
        },
        loading: () => LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: const AppLoadingIndicator(size: 28),
            ),
          ),
        ),
        error: (e, _) => LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: Center(child: Text(mapErrorToUserMessage(e, l10n))),
            ),
          ),
        ),
      ),
    );
  }
}
