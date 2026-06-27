import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/album_providers.dart';
import '../providers/config_provider.dart';
import '../providers/repository_provider.dart';
import '../utils/error_mapper.dart';
import '../utils/favorite_action.dart';
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
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery?.trim() ?? '';
    _controller.text = _query;
  }

  void _search() {
    _debounceTimer?.cancel();
    final trimmed = _controller.text.trim();
    if (trimmed == _query) return;
    setState(() {
      _query = trimmed;
    });
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _query = '');
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 500), _search);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
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
          onSubmitted: (_) => _search(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _search),
        ],
      ),
      body: results.when(
        data: (items) {
          if (_query.isEmpty) {
            return Center(child: Text(l10n.searchPrompt));
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
