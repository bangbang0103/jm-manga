import 'package:flutter/material.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/album.dart';
import '../models/reading_progress.dart';
import '../widgets/loading_indicator.dart';
import '../providers/album_providers.dart';
import '../providers/repository_provider.dart';
import '../utils/error_mapper.dart';
import '../utils/favorite_action.dart';
import '../widgets/animations/staggered_list.dart';
import '../widgets/manga_cover_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _categorySections = [
    'hanman',
    'hanmansfw',
    'single',
    'another',
    'short',
    'doujin',
    'meiman',
  ];

  static String _categoryName(AppLocalizations l10n, String slug) {
    return switch (slug) {
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

  void _refreshHome(WidgetRef ref) {
    ref.invalidate(readingProgressProvider);
    for (final slug in _categorySections) {
      ref.invalidate(categoryProvider(CategoryKey(slug, 'mr')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/app_icon.png',
                width: 34,
                height: 34,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.appTitle,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshHome(ref),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: 1 + _categorySections.length,
          itemBuilder: (context, index) {
            if (index == 0) return const _RecentReadSection();
            return _HorizontalCategorySection(slug: _categorySections[index - 1]);
          },
        ),
      ),
    );
  }
}

class _HorizontalCategorySection extends ConsumerWidget {
  final String slug;

  const _HorizontalCategorySection({required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final title = HomeScreen._categoryName(l10n, slug);
    final asyncItems = ref.watch(categoryProvider(CategoryKey(slug, 'mr')));
    final favoriteIdsAsync = ref.watch(favoriteAlbumIdsProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/category/$slug'),
                  child: Text(l10n.actionViewAll),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: asyncItems.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(child: Text(l10n.emptyNoItems));
                }
                return StaggeredList<AlbumItem>(
                  scrollDirection: Axis.horizontal,
                  items: items.take(10).toList(),
                  separatorExtent: 12,
                  duration: const Duration(milliseconds: 320),
                  staggerDelay: const Duration(milliseconds: 40),
                  itemBuilder: (context, item, index) {
                    final repo = ref.read(apiRepositoryProvider);
                    final isFavorite =
                        favoriteIdsAsync.valueOrNull?.contains(item.albumId) ??
                        false;
                    return SizedBox(
                      width: 140,
                      child: MangaCoverCard(
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
                      ),
                    );
                  },
                );
              },
              loading: () => const AppLoadingIndicator(size: 28),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(mapErrorToUserMessage(e, l10n)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentReadSection extends ConsumerWidget {
  const _RecentReadSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final recentAsync = ref.watch(readingProgressProvider);
    final favoriteIdsAsync = ref.watch(favoriteAlbumIdsProvider);

    return recentAsync.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final displayed = items.take(5).toList();
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.sectionRecentRead,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.go('/?tab=library&subTab=recent'),
                      child: Text(l10n.actionViewAll),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: StaggeredList<ReadingProgress>(
                  scrollDirection: Axis.horizontal,
                  items: displayed,
                  separatorExtent: 12,
                  duration: const Duration(milliseconds: 320),
                  staggerDelay: const Duration(milliseconds: 40),
                  itemBuilder: (context, item, index) {
                    final repo = ref.read(apiRepositoryProvider);
                    final isFavorite =
                        favoriteIdsAsync.valueOrNull?.contains(item.albumId) ??
                        false;
                    return SizedBox(
                      width: 140,
                      child: MangaCoverCard(
                        title: item.title ?? 'Album ${item.albumId}',
                        badgeText: item.localizedBadgeText(l10n),
                        imageProvider: repo.imageProvider(
                          repo.coverUrl(item.albumId),
                        ),
                        isFavorite: isFavorite,
                        onTap: () => context.push('/album/${item.albumId}'),
                        onFavorite: () => toggleFavoriteAction(
                          context,
                          ref,
                          albumId: item.albumId,
                          item: AlbumItem(
                            albumId: item.albumId,
                            title: item.title ?? 'Album ${item.albumId}',
                            tags: const [],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: AppLoadingIndicator(size: 24),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
