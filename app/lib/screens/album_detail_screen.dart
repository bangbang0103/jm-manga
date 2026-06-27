import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/album.dart';
import '../models/reading_progress.dart';
import '../models/reader_initial_data.dart';
import '../widgets/animated_favorite_button.dart';
import '../widgets/app_dropdown.dart';
import '../widgets/error_placeholder.dart';
import '../widgets/loading_indicator.dart';
import '../providers/album_providers.dart';
import '../providers/repository_provider.dart';
import '../data/favorite_service.dart';
import '../utils/error_mapper.dart';
import '../utils/favorite_action.dart';
import '../utils/image_download.dart';
import '../utils/top_toast.dart';

class AlbumDetailScreen extends ConsumerStatefulWidget {
  final String albumId;

  const AlbumDetailScreen({super.key, required this.albumId});

  @override
  ConsumerState<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends ConsumerState<AlbumDetailScreen> {
  final _scrollController = ScrollController();
  final List<GlobalKey> _chapterKeys = [];
  int? _jumpTarget;
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final show = _scrollController.offset > 400;
      if (show != _showScrollToTop) {
        setState(() => _showScrollToTop = show);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _copyAlbumId(BuildContext context, String id) async {
    await Clipboard.setData(ClipboardData(text: id));
    if (context.mounted) {
      TopToast.show(
        context,
        AppLocalizations.of(context)!.copiedToClipboard,
        type: TopToastType.success,
      );
    }
  }

  void _showCover(BuildContext context, String imageUrl) {
    final imageProvider = ref.read(apiRepositoryProvider).imageProvider(imageUrl);
    showDialog(
      context: context,
      builder: (_) => Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: GestureDetector(
              onLongPress: () => showImageDownloadSheet(context, ref, url: imageUrl, fallbackName: 'cover.jpg'),
              behavior: HitTestBehavior.translucent,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Image(
                  image: imageProvider,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  void _jumpToChapter(int index) {
    setState(() => _jumpTarget = index);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final key = _chapterKeys[index];
      final context = key.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          alignment: 0.1,
        );
      }
      setState(() => _jumpTarget = null);
    });
  }

  String _stringValue(dynamic value) => value == null ? '' : value.toString();

  int? _progressPercent(ReadingProgress? progress) {
    if (progress == null) return null;
    if (progress.isFinished) return 100;
    final pageCount = progress.pageCount;
    if (pageCount != null && pageCount > 0) {
      return ((progress.imageIndex + 1) / pageCount * 100)
          .round()
          .clamp(0, 99);
    }
    return null;
  }

  Widget _buildProgressBar(ThemeData theme, int? percent) {
    if (percent == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      child: Stack(
        children: [
          Container(
            height: 4,
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          FractionallySizedBox(
            widthFactor: percent / 100,
            child: Container(
              height: 4,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  ReadingProgress? _findProgress(
    List<ReadingProgress> progressList,
    String photoId,
  ) {
    try {
      return progressList.firstWhere((p) => p.photoId == photoId);
    } catch (_) {
      return null;
    }
  }

  String? _resumePhotoId(
    List<Map<String, dynamic>> episodes,
    List<ReadingProgress> progressList,
  ) {
    if (episodes.isEmpty) return null;
    if (progressList.isEmpty) {
      return _stringValue(episodes.first['photo_id']);
    }

    // Prefer the latest read chapter if not finished.
    final sorted = progressList.toList()
      ..sort((a, b) => b.lastReadAt.compareTo(a.lastReadAt));
    final latest = sorted.first;
    if (!latest.isFinished) return latest.photoId;

    // Otherwise find the first episode that is not finished.
    for (final ep in episodes) {
      final photoId = _stringValue(ep['photo_id']);
      if (photoId.isEmpty) continue;
      final progress = _findProgress(progressList, photoId);
      if (progress == null || !progress.isFinished) return photoId;
    }

    return episodes.first['photo_id'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final albumAsync = ref.watch(albumDetailProvider(widget.albumId));
    final progressAsync = ref.watch(albumProgressProvider(widget.albumId));
    final favoriteStatusAsync = ref.watch(favoriteStatusProvider(widget.albumId));
    final showAppBar = albumAsync.isLoading || albumAsync.hasError;

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              leading: const BackButton(),
              title: const SizedBox.shrink(),
            )
          : null,
      body: albumAsync.when(
        data: (album) {
          final progressList = progressAsync.valueOrNull ?? [];
          final repo = ref.read(apiRepositoryProvider);
          final coverUrl = album.coverUrl ?? repo.coverUrl(album.albumId);
          final episodes = album.episodes;
          _chapterKeys
            ..clear()
            ..addAll(List.generate(episodes.length, (_) => GlobalKey()));

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(albumDetailProvider(widget.albumId));
              ref.invalidate(albumProgressProvider(widget.albumId));
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          album.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _copyAlbumId(context, album.albumId),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#${album.albumId}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => _showCover(context, coverUrl),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 120,
                              child: Image(
                                image: repo.imageProvider(coverUrl),
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const SizedBox(
                                    height: 180,
                                    child: ImagePlaceholder(),
                                  );
                                },
                                errorBuilder: (_, _, _) => const SizedBox(
                                  height: 180,
                                  child: ImageErrorPlaceholder(),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                album.title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.authorLabel(album.author),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (album.likes != null || album.views != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    [
                                      if (album.likes != null)
                                        l10n.likesLabel(album.likes!),
                                      if (album.views != null)
                                        l10n.viewsLabel(album.views!),
                                    ].join('  •  '),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: album.tags.map((tag) {
                                  return ActionChip(
                                    label: Text(tag),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    onPressed: () => context.push(
                                      '/search?q=${Uri.encodeComponent(tag)}',
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.synopsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          album.description,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.chaptersTitle(episodes.length),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (episodes.length > 1)
                              AppDropdownMenu<int>(
                                value: _jumpTarget ?? 0,
                                items: List.generate(episodes.length, (i) => i),
                                width: 160,
                                label: l10n.jumpToHint,
                                requestFocusOnTap: true,
                                labelFor: (index) =>
                                    l10n.chapterTitle(index + 1),
                                trailingIconFor: (index) {
                                  final photoId = _stringValue(
                                    episodes[index]['photo_id'],
                                  );
                                  final progress = _findProgress(
                                    progressList,
                                    photoId,
                                  );
                                  if (progress == null) {
                                    return Icon(
                                      Icons.circle_outlined,
                                      size: 16,
                                      color: theme.colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.4),
                                    );
                                  }
                                  if (progress.isFinished) {
                                    return Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    );
                                  }
                                  return Icon(
                                    Icons.play_circle_outline,
                                    size: 16,
                                    color: theme.colorScheme.secondary,
                                  );
                                },
                                onSelected: (index) {
                                  if (index != null) _jumpToChapter(index);
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final ep = episodes[index];
                      final photoId = _stringValue(ep['photo_id']);
                      final title = _stringValue(ep['title']).isNotEmpty
                          ? _stringValue(ep['title'])
                          : l10n.chapterTitle(index + 1);
                      final progress = _findProgress(progressList, photoId);
                      final percent = _progressPercent(progress);

                      return Card(
                        key: _chapterKeys[index],
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: CircleAvatar(child: Text('${index + 1}')),
                              title: Text(title),
                              trailing: percent != null
                                  ? Text(
                                      l10n.badgePercent(percent),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    )
                                  : null,
                              onTap: () => context.push(
                                '/reader/$photoId',
                                extra: ReaderInitialData(
                                  album: album,
                                  progressList: progressList,
                                ),
                              ),
                            ),
                            _buildProgressBar(theme, percent),
                          ],
                        ),
                      );
                    }, childCount: episodes.length),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            ),
          );
        },
        loading: () => const AppLoadingIndicator(size: 28),
        error: (e, _) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(albumDetailProvider(widget.albumId));
            ref.invalidate(albumProgressProvider(widget.albumId));
          },
          child: ErrorPlaceholder(
            message: mapErrorToUserMessage(e, l10n),
            onRetry: () {
              ref.invalidate(albumDetailProvider(widget.albumId));
              ref.invalidate(albumProgressProvider(widget.albumId));
            },
            retryLabel: l10n.actionRetry,
          ),
        ),
      ),
      bottomNavigationBar: albumAsync.maybeWhen(
        data: (album) {
          final progressList = progressAsync.valueOrNull ?? [];
          final photoId = _resumePhotoId(album.episodes, progressList);
          if (photoId == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: () => context.push(
                  '/reader/$photoId',
                  extra: ReaderInitialData(
                    album: album,
                    progressList: progressList,
                  ),
                ),
                child: Text(l10n.readNow),
              ),
            ),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
      floatingActionButton: albumAsync.maybeWhen(
        data: (album) {
          final isFavorite =
              favoriteStatusAsync.valueOrNull ?? album.isFavorite;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_showScrollToTop)
                FloatingActionButton.small(
                  heroTag: 'album_scroll_top_${widget.albumId}',
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  foregroundColor: theme.colorScheme.onSurface,
                  onPressed: () => _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  ),
                  child: const Icon(Icons.arrow_upward),
                ),
              if (_showScrollToTop) const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'album_favorite_${widget.albumId}',
                backgroundColor: theme.colorScheme.surfaceContainerHigh,
                onPressed: () => toggleFavoriteAction(
                  context,
                  ref,
                  albumId: album.albumId,
                  item: AlbumItem(
                    albumId: album.albumId,
                    title: album.title,
                    tags: album.tags,
                    coverUrl: album.coverUrl ??
                        ref.read(apiRepositoryProvider).coverUrl(album.albumId),
                  ),
                ),
                child: AnimatedFavoriteButton(
                  isFavorite: isFavorite,
                  onPressed: null,
                  size: 24,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}
