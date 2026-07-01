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
import '../utils/tag_query_parser.dart';
import '../utils/top_toast.dart';
import '../widgets/animations/staggered_grid.dart';
import '../widgets/error_placeholder.dart';
import '../widgets/filter_chip_bar.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/manga_cover_card.dart';
import '../widgets/search_filter_sheet.dart';
import '../widgets/tag_chip.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  // 来自搜索框的普通关键词与 +/- 语法
  String _keywords = '';
  List<String> _inlineIncludes = const <String>[];
  List<String> _inlineExcludes = const <String>[];

  // 来自过滤面板的临时状态
  List<String> _panelExcludes = const <String>[];
  List<String> _allowedGlobal = const <String>[];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery?.trim() ?? '';
    if (initial.isNotEmpty) {
      final parsed = _parseSearchInput(initial);
      _keywords = parsed.keywords;
      _inlineIncludes = parsed.includes;
      _inlineExcludes = parsed.excludes;
      _allowedGlobal = parsed.allowedGlobal;
      _controller.text = _keywords;
    }
  }

  SearchRequest _parseSearchInput(String input) {
    final config = ref.read(configProvider);
    return TagQueryParser.parse(input, globalExcludes: config.excludedTags);
  }

  static String _tagKey(String tag) => tag.trim().toLowerCase();

  static List<String> _withoutTags(
    List<String> tags,
    Iterable<String> removed,
  ) {
    final removedKeys = removed.map(_tagKey).toSet();
    return tags.where((tag) => !removedKeys.contains(_tagKey(tag))).toList();
  }

  static List<String> _mergeTags(List<String> tags, Iterable<String> added) {
    final merged = [...tags];
    for (final tag in added) {
      if (tag.trim().isEmpty) continue;
      if (!merged.any((existing) => _tagKey(existing) == _tagKey(tag))) {
        merged.add(tag);
      }
    }
    return merged;
  }

  SearchRequest _buildRequest() {
    final config = ref.read(configProvider);
    return SearchRequest(
      keywords: _keywords,
      includes: _inlineIncludes,
      excludes: {..._inlineExcludes, ..._panelExcludes}.toList(),
      globalExcludes: config.excludedTags,
      allowedGlobal: _allowedGlobal,
    );
  }

  void _search({bool saveToHistory = false}) {
    final parsed = _parseSearchInput(_controller.text);
    setState(() {
      _keywords = parsed.keywords;
      _inlineIncludes = _withoutTags(_inlineIncludes, parsed.excludes);
      _inlineIncludes = _mergeTags(_inlineIncludes, parsed.includes);
      _inlineExcludes = _withoutTags(_inlineExcludes, [
        ...parsed.includes,
        ...parsed.allowedGlobal,
      ]);
      _panelExcludes = _withoutTags(_panelExcludes, [
        ...parsed.includes,
        ...parsed.allowedGlobal,
      ]);
      _inlineExcludes = _mergeTags(_inlineExcludes, parsed.excludes);
      _allowedGlobal = _withoutTags(_allowedGlobal, parsed.excludes);
      _allowedGlobal = _mergeTags(_allowedGlobal, parsed.allowedGlobal);
      _controller.text = _keywords;
    });

    final request = _buildRequest();
    if (saveToHistory && request.historyQuery.isNotEmpty) {
      ref.read(searchHistoryProvider.notifier).add(request.historyQuery);
    }
  }

  void _onSearchChanged(String value) {
    // 搜索框清空时回到历史页，同时清空所有临时过滤条件。
    if (value.trim().isEmpty) {
      setState(() {
        _keywords = '';
        _inlineIncludes = const <String>[];
        _inlineExcludes = const <String>[];
        _panelExcludes = const <String>[];
        _allowedGlobal = const <String>[];
      });
    }
  }

  void _searchFromHistory(String query) {
    final parsed = _parseSearchInput(query);
    setState(() {
      _keywords = parsed.keywords;
      _inlineIncludes = parsed.includes;
      _inlineExcludes = parsed.excludes;
      _panelExcludes = const <String>[];
      _allowedGlobal = parsed.allowedGlobal;
      _controller.text = _keywords;
    });
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

  void _showFilterSheet() {
    final config = ref.read(configProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SearchFilterSheet(
        currentExcludes: {..._inlineExcludes, ..._panelExcludes}.toList(),
        globalExcludes: config.excludedTags,
        allowedGlobal: _allowedGlobal,
        onExcludeAdded: (tag) {
          setState(() {
            _panelExcludes = {..._panelExcludes, tag}.toList();
          });
        },
        onExcludeRemoved: (tag) {
          setState(() {
            _inlineExcludes = _inlineExcludes.where((t) => t != tag).toList();
            _panelExcludes = _panelExcludes.where((t) => t != tag).toList();
          });
        },
        onGlobalAllowedChanged: (tag, allowed) {
          setState(() {
            if (allowed) {
              _allowedGlobal = {..._allowedGlobal, tag}.toList();
            } else {
              _allowedGlobal = _allowedGlobal.where((t) => t != tag).toList();
            }
          });
        },
      ),
    );
  }

  void _removeKeyword(String keyword) {
    _controller.clear();
    _search(saveToHistory: false);
  }

  void _removeInclude(String tag) {
    setState(() {
      _inlineIncludes = _inlineIncludes.where((t) => t != tag).toList();
      _allowedGlobal = _allowedGlobal.where((t) => t != tag).toList();
    });
  }

  void _removeExclude(String tag) {
    setState(() {
      _inlineExcludes = _inlineExcludes.where((t) => t != tag).toList();
      _panelExcludes = _panelExcludes.where((t) => t != tag).toList();
    });
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
    final config = ref.watch(configProvider);

    final request = SearchRequest(
      keywords: _keywords,
      includes: _inlineIncludes,
      excludes: {..._inlineExcludes, ..._panelExcludes}.toList(),
      globalExcludes: config.excludedTags,
      allowedGlobal: _allowedGlobal,
    );
    final hasUserInput =
        _keywords.isNotEmpty ||
        _inlineIncludes.isNotEmpty ||
        _inlineExcludes.isNotEmpty ||
        _panelExcludes.isNotEmpty ||
        _allowedGlobal.isNotEmpty;

    final results = hasUserInput
        ? ref.watch(searchProvider(request))
        : const AsyncValue<List<dynamic>>.data([]);
    final history = ref.watch(searchHistoryProvider);

    final includeTags = {
      ...request.includes,
      ...request.allowedGlobal,
    }.toList();
    final excludeTags = request.excludes;

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
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: l10n.searchFilterTitle,
            onPressed: _showFilterSheet,
          ),
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
      body: Column(
        children: [
          if (hasUserInput)
            FilterChipBar(
              keywords: request.keywords,
              includes: includeTags,
              excludes: excludeTags,
              onRemoveKeyword: _removeKeyword,
              onRemoveInclude: _removeInclude,
              onRemoveExclude: _removeExclude,
            ),
          Expanded(
            child: !hasUserInput
                ? _SearchHistoryView(
                    history: history,
                    onTap: _searchFromHistory,
                    onDelete: _deleteHistory,
                    onClearAll: _confirmClearHistory,
                  )
                : results.when(
                    data: (items) {
                      final notifier = ref.read(
                        searchProvider(request).notifier,
                      );
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
                      final notifier = ref.read(
                        searchProvider(request).notifier,
                      );
                      return ErrorPlaceholder(
                        message: mapErrorToUserMessage(e, l10n),
                        onRetry: notifier.search,
                        retryLabel: l10n.actionRetry,
                      );
                    },
                  ),
          ),
        ],
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
              TextButton(onPressed: onClearAll, child: Text(l10n.clearAll)),
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
                return TagChip(
                  label: query,
                  onTap: () => onTap(query),
                  onDelete: () => onDelete(query),
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
