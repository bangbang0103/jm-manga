import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/album.dart';
import '../models/reading_progress.dart';
import '../providers/account_provider.dart';
import '../providers/album_providers.dart';
import '../providers/config_provider.dart';
import '../providers/library_signal_provider.dart';
import '../providers/repository_provider.dart';
import '../utils/error_mapper.dart';
import '../utils/favorite_action.dart';
import '../utils/top_toast.dart';
import '../widgets/animations/staggered_grid.dart';
import '../widgets/loading_indicator.dart';
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

  // Recent read: search + batch delete + undo
  final _recentSearchController = TextEditingController();
  bool _isEditingRecent = false;
  final Set<String> _selectedAlbumIds = <String>{};
  bool _isDeleting = false;
  Map<String, List<ReadingProgress>> _lastDeleted = {};
  bool _showUndo = false;

  int _lastTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _lastTabIndex = _tabController.index;
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _recentSearchController.dispose();
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

  void _handleTabChange() {
    if (_tabController.index == _lastTabIndex) return;
    _lastTabIndex = _tabController.index;
    _onTabTapped(_lastTabIndex);
  }

  void _onTabTapped(int index) {
    setState(() {
      _resetRecentEditState();
      _recentSearchController.clear();
    });
    if (index == 0) {
      unawaited(ref.read(favoritesProvider.notifier).refresh());
    } else {
      unawaited(ref.read(readingProgressProvider.notifier).load());
    }
  }

  void _resetRecentEditState() {
    _isEditingRecent = false;
    _selectedAlbumIds.clear();
    _isDeleting = false;
    _lastDeleted = {};
    _showUndo = false;
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

  void _enterRecentEditMode({String? selectAlbumId}) {
    setState(() {
      _isEditingRecent = true;
      _showUndo = false;
      if (selectAlbumId != null) {
        _selectedAlbumIds.add(selectAlbumId);
      }
    });
  }

  void _toggleSelection(String albumId) {
    if (_isDeleting) return;
    setState(() {
      if (_selectedAlbumIds.contains(albumId)) {
        _selectedAlbumIds.remove(albumId);
      } else {
        _selectedAlbumIds.add(albumId);
      }
    });
  }

  void _selectAll(Iterable<String> albumIds) {
    if (_isDeleting) return;
    setState(() => _selectedAlbumIds.addAll(albumIds));
  }

  void _deselectAll() {
    if (_isDeleting) return;
    setState(() => _selectedAlbumIds.clear());
  }

  Future<void> _deleteSelected() async {
    if (_selectedAlbumIds.isEmpty || _isDeleting) return;

    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(apiRepositoryProvider);
    final notifier = ref.read(readingProgressProvider.notifier);

    // Snapshot selection and enter busy state before any async work.
    final selectedSnapshot = _selectedAlbumIds.toList();
    setState(() => _isDeleting = true);

    try {
      // Backup progress for undo.
      final backup = <String, List<ReadingProgress>>{};
      for (final albumId in selectedSnapshot) {
        backup[albumId] = await repo.getAlbumProgress(albumId);
      }

      await notifier.delete(selectedSnapshot);
      ref.invalidate(homeRecentProgressProvider);
      if (mounted) {
        setState(() {
          _lastDeleted = backup;
          _showUndo = true;
          _resetSelectionOnly();
        });
        TopToast.show(
          context,
          l10n.recentDeleted(_lastDeleted.length),
          type: TopToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        TopToast.show(
          context,
          mapErrorToUserMessage(e, l10n),
          type: TopToastType.error,
        );
      }
    }
  }

  void _resetSelectionOnly() {
    _isEditingRecent = false;
    _selectedAlbumIds.clear();
    _isDeleting = false;
  }

  Future<void> _undoDelete() async {
    if (!_showUndo || _lastDeleted.isEmpty || _isDeleting) return;

    final repo = ref.read(apiRepositoryProvider);
    final notifier = ref.read(readingProgressProvider.notifier);

    setState(() => _isDeleting = true);
    try {
      for (final progresses in _lastDeleted.values) {
        for (final progress in progresses) {
          await repo.syncProgress(progress);
        }
      }
      await notifier.refresh();
      ref.invalidate(homeRecentProgressProvider);

      if (mounted) {
        setState(() {
          _lastDeleted = {};
          _showUndo = false;
          _isDeleting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        final l10n = AppLocalizations.of(context)!;
        TopToast.show(
          context,
          mapErrorToUserMessage(e, l10n),
          type: TopToastType.error,
        );
      }
    }
  }

  Future<void> _handleRecentRefresh() async {
    setState(() {
      _resetRecentEditState();
      _recentSearchController.clear();
    });
    await ref.read(readingProgressProvider.notifier).load();
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

    final recentItems = reading.valueOrNull ?? <ReadingProgress>[];
    final recentAlbumIds = recentItems.map((p) => p.albumId).toList();

    return Scaffold(
      appBar: AppBar(
        title: _isEditingRecent
            ? Text(l10n.recentSelectedCount(_selectedAlbumIds.length))
            : Text(l10n.libraryTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.tabFavorite),
            Tab(text: l10n.tabRecentRead),
          ],
        ),
      ),
      bottomNavigationBar: _isEditingRecent
          ? _buildRecentEditBottomBar(recentAlbumIds)
          : null,
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) => favoritesNotifier.search(value),
              ),
            ),
          if (_tabController.index == 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _recentSearchController,
                      enabled: !_isEditingRecent,
                      decoration: InputDecoration(
                        hintText: l10n.recentSearchHint,
                        prefixIcon: const Icon(Icons.search),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (value) => ref
                          .read(readingProgressProvider.notifier)
                          .search(value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildRecentEditOrUndoButton(recentItems.isNotEmpty),
                ],
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
                  onRefresh: _handleRecentRefresh,
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
                  emptyMessage: _recentSearchController.text.trim().isEmpty
                      ? l10n.recentEmpty
                      : l10n.recentSearchEmpty,
                  emptyAction: _recentSearchController.text.trim().isEmpty
                      ? (
                          label: l10n.recentBrowseManga,
                          onPressed: () => context.go('/?tab=home'),
                        )
                      : null,
                  isEditing: _isEditingRecent,
                  selectedIds: _selectedAlbumIds,
                  onToggleSelection: _toggleSelection,
                  onLongPress: (progress) => _enterRecentEditMode(
                    selectAlbumId: progress.albumId,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEditOrUndoButton(bool hasItems) {
    final l10n = AppLocalizations.of(context)!;
    final buttonStyle = TextButton.styleFrom(
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 12),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showUndo)
          TextButton(
            style: buttonStyle,
            onPressed: _isDeleting ? null : _undoDelete,
            child: Text(l10n.recentUndo),
          ),
        TextButton(
          style: buttonStyle,
          onPressed: _isDeleting || (!_isEditingRecent && !hasItems)
              ? null
              : () {
                  if (_isEditingRecent) {
                    setState(_resetRecentEditState);
                  } else {
                    _enterRecentEditMode();
                  }
                },
          child: Text(_isEditingRecent ? l10n.recentCancel : l10n.recentEdit),
        ),
      ],
    );
  }

  Widget _buildRecentEditBottomBar(List<String> visibleAlbumIds) {
    final l10n = AppLocalizations.of(context)!;
    final allSelected = visibleAlbumIds.isNotEmpty &&
        visibleAlbumIds.every(_selectedAlbumIds.contains);

    final theme = Theme.of(context);

    return BottomAppBar(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: _isDeleting
                    ? null
                    : allSelected
                        ? _deselectAll
                        : () => _selectAll(visibleAlbumIds),
                child: Text(
                  allSelected ? l10n.recentDeselectAll : l10n.recentSelectAll,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: _isDeleting || _selectedAlbumIds.isEmpty
                    ? null
                    : _deleteSelected,
                child: _isDeleting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : Text(l10n.recentDelete(_selectedAlbumIds.length)),
              ),
            ],
          ),
        ),
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
    bool isEditing = false,
    Set<String> selectedIds = const <String>{},
    ValueChanged<String>? onToggleSelection,
    ValueChanged<T>? onLongPress,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
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
                          FilledButton(
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
                final isSelected =
                    albumId != null && selectedIds.contains(albumId);
                final isFavorite = albumId != null &&
                    (favoriteIdsAsync.valueOrNull?.contains(albumId) ?? false);

                Widget card = MangaCoverCard(
                  title: titleFor(item),
                  badgeText: badgeTextFor?.call(item),
                  imageProvider: repo.imageProvider(coverUrlFor(item)),
                  isFavorite: isFavorite,
                  onTap: isEditing && albumId != null
                      ? () => onToggleSelection?.call(albumId)
                      : () => context.push(routeFor(item)),
                  onLongPress: onLongPress != null && !isEditing
                      ? () => onLongPress(item)
                      : null,
                  onFavorite: isEditing || albumId == null
                      ? null
                      : () => toggleFavoriteAction(
                          context,
                          ref,
                          albumId: albumId,
                          item: itemForFavorite?.call(item),
                        ),
                );

                if (isEditing && albumId != null) {
                  card = Stack(
                    children: [
                      card,
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _isDeleting
                              ? null
                              : () => onToggleSelection?.call(albumId),
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                size: 22,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return card;
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
