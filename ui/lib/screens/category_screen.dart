import 'package:flutter/material.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/album.dart';
import '../widgets/loading_indicator.dart';
import '../providers/account_provider.dart';
import '../providers/album_providers.dart';
import '../providers/config_provider.dart';
import '../providers/repository_provider.dart';
import '../utils/favorite_action.dart';
import '../widgets/manga_cover_card.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  final String category;

  const CategoryScreen({super.key, required this.category});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  String _order = 'mr';

  static const _orders = ['mr', 'mv', 'tr', 'tf'];

  static String _orderLabel(AppLocalizations l10n, String slug) {
    return switch (slug) {
      'mr' => l10n.orderMostRecent,
      'mv' => l10n.orderMostViewed,
      'tr' => l10n.orderTopRated,
      'tf' => l10n.orderTopFavorite,
      _ => slug,
    };
  }

  static String _categoryName(AppLocalizations l10n, String slug) {
    return switch (slug) {
      'doujin' => l10n.categoryDoujin,
      'hanman' => l10n.categoryHanman,
      'hanmansfw' => l10n.categoryHanmanSfw,
      'meiman' => l10n.categoryMeiman,
      'short' => l10n.categoryShort,
      'single' => l10n.categorySingle,
      'another' => l10n.categoryAnother,
      _ => l10n.categoryTitle,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final key = CategoryKey(widget.category, _order);
    final asyncItems = ref.watch(categoryProvider(key));

    return Scaffold(
      appBar: AppBar(title: Text(_categoryName(l10n, widget.category))),
      body: Column(
        children: [
          Container(
            color: theme.colorScheme.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _orders.map((slug) {
                  final selected = _order == slug;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_orderLabel(l10n, slug)),
                      selected: selected,
                      showCheckmark: false,
                      onSelected: (_) {
                        if (_order != slug) {
                          setState(() => _order = slug);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async =>
                  ref.read(categoryProvider(key).notifier).refresh(),
              child: asyncItems.when(
                data: (items) {
                  final notifier = ref.read(categoryProvider(key).notifier);
                  return NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollUpdateNotification) {
                        final metrics = notification.metrics;
                        if (metrics.extentAfter < 300) {
                          notifier.loadMore();
                        }
                      }
                      return false;
                    },
                    child: _CategoryGrid(
                      items: items,
                      hasMore: notifier.hasMore,
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
                      child: Center(
                        child: Text(l10n.errorWithMessage(e.toString())),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends ConsumerWidget {
  final List<AlbumItem> items;
  final bool hasMore;

  const _CategoryGrid({required this.items, required this.hasMore});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: Center(child: Text(l10n.emptyNoItems)),
          ),
        ),
      );
    }

    final favoriteIdsAsync = ref.watch(favoriteAlbumIdsProvider);
    final gridColumns = ref.watch(configProvider).gridColumns;

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridColumns,
        childAspectRatio: 2 / 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
            if (index == items.length) {
              return const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            final item = items[index];
            final repo = ref.read(apiRepositoryProvider);
            final account = ref.watch(selectedAccountProvider);
            final canFavorite = account != null && !account.isAnonymous;
            final isFavorite =
                favoriteIdsAsync.valueOrNull?.contains(item.albumId) ?? false;
            return MangaCoverCard(
              title: item.title,
              imageUrl: item.coverUrl ?? repo.coverUrl(item.albumId),
              imageHeaders: repo.imageHeaders,
              isFavorite: isFavorite,
              onTap: () => context.push('/album/${item.albumId}'),
              onFavorite: canFavorite
                  ? () => toggleFavoriteAction(
                      context,
                      ref,
                      albumId: item.albumId,
                    )
                  : null,
            );
          },
        );
  }
}
