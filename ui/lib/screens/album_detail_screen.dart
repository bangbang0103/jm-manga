import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/reading_progress.dart';
import '../models/reader_initial_data.dart';
import '../widgets/animated_favorite_button.dart';
import '../widgets/app_dropdown.dart';
import '../widgets/loading_indicator.dart';
import '../providers/account_provider.dart';
import '../providers/album_providers.dart';
import '../providers/repository_provider.dart';
import '../utils/favorite_action.dart';

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

  void _showCover(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              httpHeaders: ref.read(apiRepositoryProvider).imageHeaders,
              fit: BoxFit.contain,
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

  String _progressText(AppLocalizations l10n, ReadingProgress? progress) {
    if (progress == null) return l10n.progressUnread;
    if (progress.isFinished) return l10n.progressFinished;
    if (progress.imageIndex > 0) {
      return l10n.progressPage(progress.imageIndex + 1);
    }
    return l10n.progressStarted;
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

    return Scaffold(
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
                  title: Text(
                    album.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 120,
                                  child: CachedNetworkImage(
                                    imageUrl: coverUrl,
                                    httpHeaders: repo.imageHeaders,
                                    fit: BoxFit.cover,
                                    placeholder: (_, _) => const SizedBox(
                                      height: 180,
                                      child: ImagePlaceholder(),
                                    ),
                                    errorWidget: (_, _, _) => const SizedBox(
                                      height: 180,
                                      child: ImageErrorPlaceholder(),
                                    ),
                                  ),
                                ),
                              ),
                              if (ref
                                      .watch(selectedAccountProvider)
                                      ?.isAnonymous ==
                                  false)
                                Positioned(
                                  right: 4,
                                  bottom: 4,
                                  child: Material(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(20),
                                    child: AnimatedFavoriteButton(
                                      isFavorite: album.isFavorite,
                                      onPressed: () => toggleFavoriteAction(
                                        context,
                                        ref,
                                        albumId: album.albumId,
                                      ),
                                      size: 20,
                                      padding: const EdgeInsets.all(6),
                                      color: theme.colorScheme.secondary,
                                      inactiveColor:
                                          theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                            ],
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
                      final statusText = _progressText(l10n, progress);

                      return Card(
                        key: _chapterKeys[index],
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(title),
                          subtitle: Text(statusText),
                          trailing: progress?.isFinished == true
                              ? Icon(
                                  Icons.check_circle,
                                  color: theme.colorScheme.primary,
                                )
                              : progress != null
                              ? Icon(
                                  Icons.bookmark,
                                  color: theme.colorScheme.secondary,
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
        error: (e, _) =>
            Center(child: Text(l10n.errorWithMessage(e.toString()))),
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
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton.small(
              heroTag: 'album_scroll_top_${widget.albumId}',
              onPressed: () => _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              ),
              child: const Icon(Icons.arrow_upward),
            )
          : null,
    );
  }
}
