import 'package:flutter/material.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_shadows.dart';
import '../../models/album.dart';
import '../../providers/config_provider.dart';
import '../../utils/favorite_action.dart';
import '../../widgets/animated_favorite_button.dart';

/// 阅读器的覆盖工具层：顶部标题栏、底部进度/章节切换栏与收藏按钮。
class ReaderToolbar extends ConsumerWidget {
  final bool visible;
  final String title;
  final int currentIndex;
  final int pageCount;
  final bool hasFinished;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final AlbumDetail album;
  final bool isFavorite;
  final ReaderMode readerMode;
  final VoidCallback onToggleReaderMode;

  const ReaderToolbar({
    super.key,
    required this.visible,
    required this.title,
    required this.currentIndex,
    required this.pageCount,
    required this.hasFinished,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
    required this.album,
    required this.isFavorite,
    required this.readerMode,
    required this.onToggleReaderMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final showToolbar = visible;

    return Stack(
      children: [
        if (showToolbar)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              surfaceTintColor: Colors.transparent,
              title: Text(title),
              actions: [
                IconButton(
                  icon: Icon(
                    readerMode == ReaderMode.paged
                        ? Icons.view_agenda_outlined
                        : Icons.auto_stories_outlined,
                  ),
                  tooltip: readerMode == ReaderMode.paged
                      ? l10n.readerModeScroll
                      : l10n.readerModePaged,
                  onPressed: onToggleReaderMode,
                ),
              ],
            ),
          ),
        if (showToolbar)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.9),
                boxShadow: AppShadows.bottomBar,
              ),
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: hasPrevious
                          ? IconButton(
                              icon: const Icon(Icons.skip_previous),
                              onPressed: onPrevious,
                            )
                          : null,
                    ),
                    Expanded(
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                l10n.pageCounter(currentIndex + 1, pageCount),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasFinished) ...[
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(l10n.finishedBadge),
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHigh,
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                labelStyle: theme.textTheme.labelLarge,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: hasNext
                          ? IconButton(
                              icon: const Icon(Icons.skip_next),
                              onPressed: onNext,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          bottom: showToolbar ? 96 : 24,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'reader_favorite',
            backgroundColor: theme.colorScheme.surfaceContainerHigh.withValues(
              alpha: 0.95,
            ),
            onPressed: () => toggleFavoriteAction(
              context,
              ref,
              albumId: album.albumId,
              item: AlbumItem(
                albumId: album.albumId,
                title: album.title,
                tags: const [],
                coverUrl: album.coverUrl,
              ),
            ),
            child: AnimatedFavoriteButton(
              isFavorite: isFavorite,
              onPressed: null,
              size: 24,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}
