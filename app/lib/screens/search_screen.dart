import 'package:flutter/material.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/album_providers.dart';
import '../providers/config_provider.dart';
import '../providers/repository_provider.dart';
import '../providers/search_history_provider.dart';
import '../utils/error_mapper.dart';
import '../utils/favorite_action.dart';
import '../utils/top_toast.dart';
import '../widgets/animations/staggered_grid.dart';
import '../widgets/error_placeholder.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/manga_cover_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  late String _query;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery?.trim() ?? '';
    _controller.text = _query;
  }

  void _search({bool saveToHistory = false}) {
    final trimmed = _controller.text.trim();

    if (saveToHistory && trimmed.isNotEmpty) {
      ref.read(searchHistoryProvider.notifier).add(trimmed);
    }

    if (trimmed == _query) return;
    setState(() {
      _query = trimmed;
    });
  }

  void _onSearchChanged(String value) {
    // 不再输入过程中自动搜索，只有点击搜索按钮/键盘提交/历史 chip 时才搜索。
    if (value.trim().isEmpty) {
      setState(() => _query = '');
    }
  }

  void _searchFromHistory(String query) {
    _controller.text = query;
    _controller.selection = TextSelection.collapsed(offset: query.length);
    _search(saveToHistory: true);
  }

  Future<void> _deleteHistory(String query) async {
    await ref.read(searchHistoryProvider.notifier).remove(query);
    if (mounted) {
      TopToast.show(
        context,
        AppLocalizations.of(context)!.searchHistoryDeleted,
        type: TopToastType.success,
      );
    }
  }

  Future<void> _confirmClearHistory() async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmClearSearchHistoryTitle),
        content: Text(l10n.confirmClearSearchHistoryBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(l10n.clearAll),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(searchHistoryProvider.notifier).clear();
      if (mounted) {
        TopToast.show(
          context,
          l10n.searchHistoryCleared,
          type: TopToastType.success,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final results = _query.isEmpty
        ? const AsyncValue<List<dynamic>>.data([])
        : ref.watch(searchProvider(_query));
    final history = ref.watch(searchHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            border: InputBorder.none,
          ),
          style: theme.textTheme.bodyLarge,
          onChanged: _onSearchChanged,
          onSubmitted: (_) => _search(saveToHistory: true),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: () => _search(saveToHistory: true),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(l10n.actionSearch),
            ),
          ),
        ],
      ),
      body: results.when(
        data: (items) {
          if (_query.isEmpty) {
            return _SearchHistoryView(
              history: history,
              onTap: _searchFromHistory,
              onDelete: _deleteHistory,
              onClearAll: _confirmClearHistory,
            );
          }
          final notifier = ref.read(searchProvider(_query).notifier);
          return RefreshIndicator(
            onRefresh: () async => notifier.search(),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification &&
                    notification.metrics.extentAfter < 300) {
                  notifier.loadMore();
                }
                return false;
              },
              child: _SearchGrid(
                items: items.cast<dynamic>(),
                hasMore: notifier.hasMore,
              ),
            ),
          );
        },
        loading: () => const AppLoadingIndicator(),
        error: (e, _) {
          final notifier = ref.read(searchProvider(_query).notifier);
          return ErrorPlaceholder(
            message: mapErrorToUserMessage(e, l10n),
            onRetry: notifier.search,
            retryLabel: l10n.actionRetry,
          );
        },
      ),
    );
  }
}

class _SearchHistoryView extends StatelessWidget {
  final List<String> history;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onDelete;
  final VoidCallback onClearAll;

  const _SearchHistoryView({
    required this.history,
    required this.onTap,
    required this.onDelete,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (history.isEmpty) {
      return Center(child: Text(l10n.emptySearchHistory));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.searchHistoryTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onClearAll,
                child: Text(l10n.clearAll),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: history.map((query) {
                return InputChip(
                  label: Text(query),
                  deleteIcon: const Icon(Icons.close, size: 20),
                  onDeleted: () => onDelete(query),
                  onPressed: () => onTap(query),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchGrid extends ConsumerWidget {
  final List<dynamic> items;
  final bool hasMore;

  const _SearchGrid({required this.items, required this.hasMore});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: Center(child: Text(l10n.searchNoResults)),
          ),
        ),
      );
    }

    final favoriteIdsAsync = ref.watch(favoriteAlbumIdsProvider);
    final gridColumns = ref.watch(configProvider).gridColumns;

    return StaggeredGrid<dynamic>(
      items: items,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridColumns,
        childAspectRatio: 2 / 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      loadingIndicator: hasMore ? const AppLoadingIndicator(size: 24) : null,
      itemBuilder: (context, item, index) {
        final repo = ref.read(apiRepositoryProvider);
        final isFavorite =
            favoriteIdsAsync.valueOrNull?.contains(item.albumId) ?? false;
        return MangaCoverCard(
          title: item.title,
          imageProvider: repo.imageProvider(
            item.coverUrl ?? repo.coverUrl(item.albumId),
          ),
          isFavorite: isFavorite,
          onTap: () => context.push('/album/${item.albumId}'),
          onFavorite: () => toggleFavoriteAction(
            context,
            ref,
            albumId: item.albumId,
            item: item,
          ),
        );
      },
    );
  }
}
