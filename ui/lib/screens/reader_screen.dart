import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/api_repository.dart';
import '../core/theme/app_shadows.dart';
import '../widgets/animated_favorite_button.dart';
import '../widgets/loading_indicator.dart';
import '../models/album.dart';
import '../models/reading_progress.dart';
import '../models/reader_initial_data.dart';
import '../providers/account_provider.dart';
import '../providers/album_providers.dart';
import '../providers/config_provider.dart';
import '../providers/repository_provider.dart';
import '../utils/favorite_action.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final String photoId;
  final ReaderInitialData? initialData;

  const ReaderScreen({super.key, required this.photoId, this.initialData});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with WidgetsBindingObserver {
  bool _showToolbar = true;
  String? _albumId;
  String? _photoId;
  String? _title;
  int _currentIndex = 0;
  bool _hasFinished = false;
  Timer? _syncTimer;
  Future<void>? _pendingSync;
  final List<GlobalKey> _imageKeys = [];
  final ScrollController _scrollController = ScrollController();
  ApiRepository? _repo;
  int _lastPreloadedIndex = -1;
  List<String> _imageUrls = [];
  String _baseUrl = '';
  int _preloadCount = 5;
  int? _episodeIndex;
  int? _pageCount;
  String? _resumeAppliedForPhotoId;
  int _resumeAttempts = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    // 退出时尽量把待发送的进度 flush 出去（fire-and-forget，但已在 onPopInvoked 中等待过）。
    (_pendingSync ?? _syncCurrentProgress());
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App 进入后台或关闭前 flush 一次进度，降低被系统杀进程时丢失的风险。
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _flushSync();
    }
  }

  Future<void> _flushSync() async {
    _syncTimer?.cancel();
    await _syncCurrentProgress();
  }

  void _invalidateAlbum() {
    final albumId = _albumId;
    if (albumId == null) return;
    ref.invalidate(albumDetailProvider(albumId));
    ref.invalidate(albumProgressProvider(albumId));
  }

  void _openChapter(String? photoId, ReaderInitialData initialData) {
    if (photoId == null || photoId.isEmpty) return;
    context.go('/reader/$photoId', extra: initialData);
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

  void _scheduleResume(String photoId, int imageIndex, int pageCount) {
    if (_resumeAppliedForPhotoId == photoId || pageCount <= 0) return;
    final target = imageIndex.clamp(0, pageCount - 1).toInt();
    _resumeAppliedForPhotoId = photoId;
    _resumeAttempts = 0;
    _currentIndex = target;
    WidgetsBinding.instance.addPostFrameCallback((_) => _resumeToIndex(target));
  }

  void _resumeToIndex(int index) {
    if (!mounted || index <= 0 || index >= _imageKeys.length) return;
    final keyContext = _imageKeys[index].currentContext;
    if (keyContext != null) {
      Scrollable.ensureVisible(
        keyContext,
        duration: Duration.zero,
        alignment: 0,
      );
      return;
    }

    if (_scrollController.hasClients && _resumeAttempts < 4) {
      _resumeAttempts += 1;
      final estimatedOffset = index * 400.0;
      final maxOffset = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(
        estimatedOffset.clamp(0.0, maxOffset).toDouble(),
      );
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _resumeToIndex(index),
      );
    }
  }

  Future<void> _syncCurrentProgress() async {
    final albumId = _albumId;
    final photoId = _photoId;
    final repo = _repo;
    if (albumId == null || photoId == null || repo == null) return;

    final future = repo.syncProgress(
      ReadingProgress(
        albumId: albumId,
        photoId: photoId,
        title: _title,
        imageIndex: _currentIndex,
        isFinished: _hasFinished,
        lastReadAt: DateTime.now().toUtc().toIso8601String(),
        episodeIndex: _episodeIndex,
        pageCount: _pageCount,
      ),
    );
    _pendingSync = future;
    try {
      await future;
    } catch (_) {
      // 进度同步失败不应影响阅读器退出；已由日志/拦截器处理。
    } finally {
      if (_pendingSync == future) {
        _pendingSync = null;
      }
    }
  }

  void _scheduleSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(seconds: 1), _syncCurrentProgress);
  }

  void _preloadImages(List<String> urls, String baseUrl, int preloadCount) {
    if (_currentIndex == _lastPreloadedIndex) return;
    _lastPreloadedIndex = _currentIndex;
    if (preloadCount <= 0 || urls.isEmpty) return;
    final end = (_currentIndex + preloadCount).clamp(0, urls.length - 1);
    for (int i = _currentIndex + 1; i <= end; i++) {
      final url = '$baseUrl${urls[i]}';
      precacheImage(CachedNetworkImageProvider(url), context);
    }
  }

  void _updateVisibleIndex() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final viewportHeight = renderBox.size.height;
    final center = viewportHeight / 2;
    int? bestIndex;
    double bestDistance = double.infinity;

    for (int i = 0; i < _imageKeys.length; i++) {
      final keyContext = _imageKeys[i].currentContext;
      if (keyContext == null) continue;
      final box = keyContext.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final position = box.localToGlobal(Offset.zero);
      final top = position.dy;
      final bottom = top + box.size.height;
      if (bottom > 0 && top < viewportHeight) {
        final distance = ((top + bottom) / 2 - center).abs();
        if (distance < bestDistance) {
          bestDistance = distance;
          bestIndex = i;
        }
      }
    }

    if (bestIndex != null && bestIndex != _currentIndex) {
      setState(() {
        _currentIndex = bestIndex!;
        if (_currentIndex >= _imageKeys.length - 1) {
          _hasFinished = true;
        }
      });
      _scheduleSync();
      _preloadImages(_imageUrls, _baseUrl, _preloadCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final photoAsync = ref.watch(photoDetailProvider(widget.photoId));
    final config = ref.watch(configProvider);
    final baseUrl = config.baseUrl;
    _baseUrl = baseUrl;
    _preloadCount = config.preloadCount;
    _repo ??= ref.read(apiRepositoryProvider);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        // 先等待最后一次进度同步完成，再刷新外部列表，避免退出时进度丢失。
        await _flushSync();
        _invalidateAlbum();
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: photoAsync.when(
          data: (photo) {
            final initialData = widget.initialData;
            if (initialData != null &&
                initialData.album.albumId == photo.albumId) {
              return _buildReaderContent(
                context,
                ref,
                photo: photo,
                album: initialData.album,
                progressList: initialData.progressList,
              );
            }

            final albumAsync = ref.watch(albumDetailProvider(photo.albumId));
            return albumAsync.when(
              data: (album) {
                final progressList =
                    ref
                        .watch(albumProgressProvider(album.albumId))
                        .valueOrNull ??
                    [];
                return _buildReaderContent(
                  context,
                  ref,
                  photo: photo,
                  album: album,
                  progressList: progressList,
                );
              },
              loading: () => const AppLoadingIndicator(size: 28),
              error: (e, _) =>
                  Center(child: Text(l10n.errorWithMessage(e.toString()))),
            );
          },
          loading: () => const AppLoadingIndicator(size: 28),
          error: (e, _) =>
              Center(child: Text(l10n.errorWithMessage(e.toString()))),
        ),
      ),
    );
  }

  Widget _buildReaderContent(
    BuildContext context,
    WidgetRef ref, {
    required PhotoDetail photo,
    required AlbumDetail album,
    required List<ReadingProgress> progressList,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final account = ref.watch(selectedAccountProvider);
    final favoriteIdsAsync = ref.watch(favoriteAlbumIdsProvider);
    final initialData = ReaderInitialData(
      album: album,
      progressList: progressList,
    );

    _albumId = album.albumId;
    _photoId = photo.photoId;
    _title = album.title;
    _pageCount = photo.imageUrls.length;
    final savedProgress = _findProgress(progressList, photo.photoId);
    if (savedProgress != null) {
      _scheduleResume(
        photo.photoId,
        savedProgress.imageIndex,
        photo.imageUrls.length,
      );
    }

    final isFavorite =
        favoriteIdsAsync.valueOrNull?.contains(album.albumId) ??
        album.isFavorite;
    final episodes = album.episodes;
    final currentIndex = episodes.indexWhere(
      (ep) => ep['photo_id'] == photo.photoId,
    );
    _episodeIndex = currentIndex >= 0 ? currentIndex : null;
    final hasPrev = currentIndex > 0;
    final hasNext = currentIndex >= 0 && currentIndex < episodes.length - 1;
    final prevPhotoId = hasPrev
        ? episodes[currentIndex - 1]['photo_id'] as String?
        : null;
    final nextPhotoId = hasNext
        ? episodes[currentIndex + 1]['photo_id'] as String?
        : null;

    if (_imageKeys.length != photo.imageUrls.length) {
      _imageKeys
        ..clear()
        ..addAll(List.generate(photo.imageUrls.length, (_) => GlobalKey()));
    }
    _imageUrls = photo.imageUrls;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadImages(_imageUrls, _baseUrl, _preloadCount);
    });

    return GestureDetector(
      onTap: () {
        setState(() {
          _showToolbar = !_showToolbar;
        });
      },
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                SchedulerBinding.instance.addPostFrameCallback(
                  (_) => _updateVisibleIndex(),
                );
              }
              return false;
            },
            child: ListView.builder(
              controller: _scrollController,
              itemCount: photo.imageUrls.length,
              itemBuilder: (context, index) {
                final url = '$_baseUrl${photo.imageUrls[index]}';
                return Container(
                  key: _imageKeys[index],
                  constraints: const BoxConstraints(minHeight: 200),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    httpHeaders: _repo!.imageHeaders,
                    fit: BoxFit.contain,
                    placeholder: (_, _) =>
                        const SizedBox(height: 400, child: ImagePlaceholder()),
                    errorWidget: (_, _, _) => const SizedBox(
                      height: 400,
                      child: ImageErrorPlaceholder(),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_showToolbar)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppBar(
                backgroundColor: theme.colorScheme.surface.withValues(
                  alpha: 0.9,
                ),
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.08),
                surfaceTintColor: Colors.transparent,
                title: Text(photo.title),
              ),
            ),
          if (_showToolbar)
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.pageCounter(
                          _currentIndex + 1,
                          photo.imageUrls.length,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasPrev)
                            IconButton(
                              icon: const Icon(Icons.skip_previous),
                              onPressed: () =>
                                  _openChapter(prevPhotoId, initialData),
                            )
                          else
                            const SizedBox(width: 48),
                          const SizedBox(width: 24),
                          if (_hasFinished)
                            Chip(label: Text(l10n.finishedBadge))
                          else
                            const SizedBox.shrink(),
                          const SizedBox(width: 24),
                          if (hasNext)
                            IconButton(
                              icon: const Icon(Icons.skip_next),
                              onPressed: () =>
                                  _openChapter(nextPhotoId, initialData),
                            )
                          else
                            const SizedBox(width: 48),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_showToolbar && account != null && !account.isAnonymous)
            Positioned(
              top: kToolbarHeight + MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'reader_favorite',
                backgroundColor: theme.colorScheme.surfaceContainerHigh
                    .withValues(alpha: 0.95),
                onPressed: () =>
                    toggleFavoriteAction(context, ref, albumId: album.albumId),
                child: AnimatedFavoriteButton(
                  isFavorite: isFavorite,
                  onPressed: null,
                  size: 24,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
