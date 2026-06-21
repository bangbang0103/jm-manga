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
import '../widgets/ranking_badge.dart';

class RankingsScreen extends ConsumerStatefulWidget {
  const RankingsScreen({super.key});

  @override
  ConsumerState<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends ConsumerState<RankingsScreen> {
  static const _periods = ['daily', 'weekly', 'monthly'];

  static const _allCategorySlugs = [
    '0',
    'hanman',
    'hanmansfw',
    'single',
    'another',
    'short',
    'doujin',
    'meiman',
  ];

  static const _sortSlugs = ['mv', 'tf', 'tr'];

  String _type = 'daily';
  String _category = '0';
  String _order = 'mv';

  static String _periodLabel(AppLocalizations l10n, String period) {
    return switch (period) {
      'daily' => l10n.periodDay,
      'weekly' => l10n.periodWeek,
      'monthly' => l10n.periodMonth,
      _ => period,
    };
  }

  static String _categoryLabel(AppLocalizations l10n, String slug) {
    return switch (slug) {
      '0' => l10n.categoryAll,
      'hanman' => l10n.categoryHanman,
      'hanmansfw' => l10n.categoryHanmanSfw,
      'single' => l10n.categorySingle,
      'another' => l10n.categoryAnother,
      'short' => l10n.categoryShort,
      'doujin' => l10n.categoryDoujin,
      'meiman' => l10n.categoryMeiman,
      _ => slug,
    };
  }

  static String _sortLabel(AppLocalizations l10n, String slug) {
    return switch (slug) {
      'mv' => l10n.sortTopView,
      'tf' => l10n.sortTopFavorite,
      'tr' => l10n.sortTopRate,
      _ => slug,
    };
  }

  static IconData _sortIcon(String slug) {
    return switch (slug) {
      'mv' => Icons.visibility_outlined,
      'tf' => Icons.favorite_outline,
      'tr' => Icons.star_outline,
      _ => Icons.sort,
    };
  }

  List<String> get _availableCategories {
    // 日榜/周榜的排行榜接口没有韩漫数据，TopView 模式下隐藏
    if (_order == 'mv' && (_type == 'daily' || _type == 'weekly')) {
      return _allCategorySlugs
          .where((slug) => slug != 'hanman' && slug != 'hanmansfw')
          .toList();
    }
    return _allCategorySlugs.toList();
  }

  void _onTypeChanged(String? value) {
    if (value == null || value == _type) return;
    setState(() {
      _type = value;
      _ensureValidCategory();
    });
  }

  void _onCategorySelected(String slug) {
    setState(() => _category = slug);
  }

  void _onSortSelected(String slug) {
    setState(() {
      _order = slug;
      _ensureValidCategory();
    });
  }

  void _ensureValidCategory() {
    final availableSlugs = _availableCategories.toSet();
    if (!availableSlugs.contains(_category)) {
      _category = '0';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(l10n.rankingsTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _PeriodSelector(
              periods: _periods,
              selected: _type,
              onSelected: _onTypeChanged,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: theme.colorScheme.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CategoryChipRow(
                  categories: _availableCategories,
                  selected: _category,
                  onSelected: _onCategorySelected,
                ),
                const SizedBox(height: 8),
                _SortSelector(
                  options: _sortSlugs,
                  selected: _order,
                  onSelected: _onSortSelected,
                ),
              ],
            ),
          ),
          Expanded(
            child: _order == 'mv'
                ? _RankingGridBody(type: _type, category: _category)
                : _CategoryGridBody(category: _category, order: _order),
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final List<String> periods;
  final String selected;
  final ValueChanged<String?> onSelected;

  const _PeriodSelector({
    required this.periods,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: periods.map((period) {
          final isSelected = period == selected;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: () => onSelected(period),
                borderRadius: BorderRadius.circular(24),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    _RankingsScreenState._periodLabel(l10n, period),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryChipRow extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const _CategoryChipRow({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: categories.map((slug) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_RankingsScreenState._categoryLabel(l10n, slug)),
              selected: selected == slug,
              showCheckmark: false,
              onSelected: (_) => onSelected(slug),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SortSelector extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const _SortSelector({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    Widget itemContent(String slug, {bool compact = false}) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_RankingsScreenState._sortIcon(slug), size: compact ? 14 : 16),
          const SizedBox(width: 6),
          Text(
            _RankingsScreenState._sortLabel(l10n, slug),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: compact ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.sortBy,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
            PopupMenuButton<String>(
              tooltip: l10n.sortBy,
              onSelected: onSelected,
              itemBuilder: (context) => options.map((slug) {
                return PopupMenuItem(value: slug, child: itemContent(slug));
              }).toList(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    itemContent(selected, compact: true),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_drop_down, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingGridBody extends ConsumerWidget {
  final String type;
  final String category;

  const _RankingGridBody({required this.type, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final key = RankingsKey(type, category);
    final asyncItems = ref.watch(rankingsProvider(key));
    final notifier = ref.read(rankingsProvider(key).notifier);

    return RefreshIndicator(
      onRefresh: () async => notifier.refresh(),
      child: asyncItems.when(
        data: (items) {
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
            child: _RankingGrid(items: items, hasMore: notifier.hasMore),
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
              child: Center(child: Text(l10n.errorWithMessage(e.toString()))),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryGridBody extends ConsumerWidget {
  final String category;
  final String order;

  const _CategoryGridBody({required this.category, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final key = CategoryKey(category, order);
    final asyncItems = ref.watch(categoryProvider(key));
    final notifier = ref.read(categoryProvider(key).notifier);

    return RefreshIndicator(
      onRefresh: () async => notifier.refresh(),
      child: asyncItems.when(
        data: (items) {
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
            child: _CategoryGrid(items: items, hasMore: notifier.hasMore),
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
              child: Center(child: Text(l10n.errorWithMessage(e.toString()))),
            ),
          ),
        ),
      ),
    );
  }
}

class _RankingGrid extends ConsumerWidget {
  final List<AlbumItem> items;
  final bool hasMore;

  const _RankingGrid({required this.items, required this.hasMore});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: Center(child: Text(l10n.rankingsEmpty)),
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
        return Stack(
          fit: StackFit.expand,
          children: [
            MangaCoverCard(
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
            ),
            Positioned(
              top: 8,
              left: 8,
              child: RankingBadge(rank: index + 1),
            ),
          ],
        );
      },
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
