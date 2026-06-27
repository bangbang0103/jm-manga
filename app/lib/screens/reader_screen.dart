import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/manga_repository.dart';
import '../core/theme/app_shadows.dart';
import '../widgets/animated_favorite_button.dart';
import '../widgets/error_placeholder.dart';
import '../widgets/loading_indicator.dart';
import '../models/album.dart';
import '../models/reading_progress.dart';
import '../models/reader_initial_data.dart';
import '../providers/album_providers.dart';
import '../providers/config_provider.dart';
import '../providers/repository_provider.dart';
import '../utils/error_mapper.dart';
import '../utils/favorite_action.dart';
import '../utils/image_download.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final String photoId;
  final ReaderInitialData? initialData;

  const ReaderScreen({super.key, required this.photoId, this.initialData});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with WidgetsBindingObserver {
  late final ValueNotifier<bool> _toolbarVisible;
  String? _albumId;
  int _currentIndex = 0;
  bool _hasFinished = false;
  Timer? _syncTimer;
  Future<void>? _pendingSync;
  final List<GlobalKey> _imageKeys = [];
  final ScrollController _scrollController = ScrollController();
  late final MangaRepository _repo;
  int _lastPreloadedIndex = -1;
  String? _resumeAppliedForPhotoId;
  int _resumeAttempts = 0;
  double _itemExtent = 400;

  @override
  void initState() {
    super.initState();
    _toolbarVisible = ValueNotifier<bool>(true);
    _repo = ref.read(apiRepositoryProvider);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    // 退出时尽量把待发送的进度 flush 出去（fire-and-forget，但已在 onPopInvoked 中等待过）。
    (_pendingSync ?? _syncCurrentProgress());
    _toolbarVisible.dispose();
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

    // 目标 item 还没被 ListView 构建出来（通常因为图片未加载）。
    // 直接跳到估算偏移量，等下一帧再尝试 ensureVisible。
    if (_scrollController.hasClients && _resumeAttempts < 20) {
      _resumeAttempts += 1;
      final targetOffset = index * _itemExtent;
      final maxOffset = _scrollController.position.maxScrollExtent;
      // itemExtent 已知后 maxScrollExtent 是准确的，clamp 不会滑到底部。
      _scrollController.jumpTo(
        targetOffset.clamp(0.0, maxOffset).toDouble(),
      );
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _resumeToIndex(index),
      );
    }
  }

  Future<void> _syncCurrentProgress() async {
    final albumId = _albumId;
    if (albumId == null) return;

    final state = _progressState;
    if (state == null) return;

    final future = _repo.syncProgress(
      ReadingProgress(
        albumId: albumId,
        photoId: state.photoId,
        title: state.title,
        imageIndex: _currentIndex,
        isFinished: _hasFinished,
        lastReadAt: DateTime.now().toUtc().toIso8601String(),
        episodeIndex: state.episodeIndex,
        pageCount: state.pageCount,
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

  void _preloadImages(
    List<String> urls, {
    required int preloadCount,
    required int targetImageWidth,
  }) {
    if (_currentIndex == _lastPreloadedIndex) return;
    _lastPreloadedIndex = _currentIndex;
    if (preloadCount <= 0 || urls.isEmpty) return;
    if (targetImageWidth <= 0) return;
    final end = (_currentIndex + preloadCount).clamp(0, urls.length - 1);
    for (int i = _currentIndex + 1; i <= end; i++) {
      final url = urls[i];
      precacheImage(
        ResizeImage(_repo.imageProvider(url), width: targetImageWidth),
        context,
      );
    }
  }

  void _updateVisibleIndex(
    ScrollMetrics metrics, {
    required int pageCount,
  }) {
    if (!metrics.hasViewportDimension || _itemExtent <= 0 || pageCount <= 0) {
      return;
    }
    final centerOffset = metrics.pixels + metrics.viewportDimension / 2;
    final index = (centerOffset / _itemExtent).round().clamp(0, pageCount - 1);

    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
        if (_currentIndex >= pageCount - 1) {
          _hasFinished = true;
        }
      });
      _scheduleSync();
    }
  }

  _ReaderProgressState? get _progressState {
    final albumId = _albumId;
    if (albumId == null) return null;
    return _ReaderProgressState(
      albumId: albumId,
      photoId: widget.photoId,
      title: _titleForAlbum[albumId],
      episodeIndex: _episodeIndexForAlbum[albumId],
      pageCount: _pageCountForAlbum[albumId],
    );
  }

  // 用于在 build 外同步进度时保存当前章节的只读派生信息。
  final Map<String, String> _titleForAlbum = {};
  final Map<String, int> _episodeIndexForAlbum = {};
  final Map<String, int> _pageCountForAlbum = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final initialData = widget.initialData;
    final photoAsync = ref.watch(photoDetailProvider(widget.photoId));
    final photoAlbumId = photoAsync.valueOrNull?.albumId;
    final needsAlbum = photoAlbumId != null &&
        (initialData == null || initialData.album.albumId != photoAlbumId);
    final albumAsync =
        needsAlbum ? ref.watch(albumDetailProvider(photoAlbumId)) : null;
    final showAppBar = photoAsync.isLoading ||
        photoAsync.hasError ||
        (albumAsync != null && (albumAsync.isLoading || albumAsync.hasError));
    final appBarTitle =
        initialData?.album.title ?? photoAsync.valueOrNull?.title ?? '';

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        // 先等待最后一次进度同步完成，再刷新外部列表，避免退出时进度丢失。
        await _flushSync();
        _invalidateAlbum();
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: showAppBar
            ? AppBar(
                leading: const BackButton(),
                title: Text(appBarTitle),
              )
            : null,
        body: photoAsync.when(
          data: (photo) {
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

            if (albumAsync == null) {
              // Already handled by the initialData branch above.
              return const SizedBox.shrink();
            }

            return albumAsync.when(
              data: (album) {
                final progressList = ref
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
              error: (e, _) => ErrorPlaceholder(
                message: mapErrorToUserMessage(e, l10n),
                onRetry: () =>
                    ref.invalidate(albumDetailProvider(photo.albumId)),
                retryLabel: l10n.actionRetry,
              ),
            );
          },
          loading: () => const AppLoadingIndicator(size: 28),
          error: (e, _) => ErrorPlaceholder(
            message: mapErrorToUserMessage(e, l10n),
            onRetry: () =>
                ref.invalidate(photoDetailProvider(widget.photoId)),
            retryLabel: l10n.actionRetry,
          ),
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
    final favoriteIdsAsync = ref.watch(favoriteAlbumIdsProvider);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final targetImageWidth =
        (screenWidth * mediaQuery.devicePixelRatio).toInt();
    // 以常见竖版漫画宽高比 0.7 估算每项高度，保证图片横向铺满。
    _itemExtent = (screenWidth / 0.7).clamp(300.0, 1200.0);
    final preloadCount = ref.read(configProvider).preloadCount;
    final initialData = ReaderInitialData(
      album: album,
      progressList: progressList,
    );

    if (_albumId != album.albumId) {
      _albumId = album.albumId;
    }
    _titleForAlbum[album.albumId] = album.title;

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
    final episodeIndex = currentIndex >= 0 ? currentIndex : null;
    _episodeIndexForAlbum[album.albumId] = episodeIndex ?? 0;
    _pageCountForAlbum[album.albumId] = photo.imageUrls.length;
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadImages(
        photo.imageUrls,
        preloadCount: preloadCount,
        targetImageWidth: targetImageWidth,
      );
    });

    return GestureDetector(
      onTap: () => _toolbarVisible.value = !_toolbarVisible.value,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                _updateVisibleIndex(
                  notification.metrics,
                  pageCount: photo.imageUrls.length,
                );
              }
              return false;
            },
            child: ListView.builder(
              controller: _scrollController,
              itemCount: photo.imageUrls.length,
              itemBuilder: (context, index) {
                final url = photo.imageUrls[index];
                return GestureDetector(
                  key: _imageKeys[index],
                  onLongPress: () => showImageDownloadSheet(
                    context,
                    ref,
                    url: url,
                    fallbackName: '${widget.photoId}_$index.jpg',
                  ),
                  behavior: HitTestBehavior.translucent,
                  child: Image(
                    image: ResizeImage(
                      _repo.imageProvider(url),
                      width: targetImageWidth,
                    ),
                    fit: BoxFit.fitWidth,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return AspectRatio(
                        aspectRatio: 0.7,
                        child: ImagePlaceholder(message: l10n.imageLoading),
                      );
                    },
                    errorBuilder: (_, _, _) => AspectRatio(
                      aspectRatio: 0.7,
                      child: ImageErrorPlaceholder(
                        message: l10n.imageLoadFailed,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _toolbarVisible,
            builder: (context, showToolbar, child) {
              return Stack(
                children: [
                  if (showToolbar)
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
                  if (showToolbar)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(
                            alpha: 0.9,
                          ),
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
                                    Chip(
                                      label: Text(l10n.finishedBadge),
                                      backgroundColor:
                                          theme.colorScheme.surfaceContainerHigh,
                                      side: BorderSide.none,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      labelStyle: theme.textTheme.labelLarge,
                                    )
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
                  Positioned(
                    bottom: showToolbar ? 120 : 24,
                    right: 16,
                    child: FloatingActionButton.small(
                      heroTag: 'reader_favorite',
                      backgroundColor: theme.colorScheme.surfaceContainerHigh
                          .withValues(alpha: 0.95),
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
            },
          ),
        ],
      ),
    );
  }
}

class _ReaderProgressState {
  final String albumId;
  final String photoId;
  final String? title;
  final int? episodeIndex;
  final int? pageCount;

  _ReaderProgressState({
    required this.albumId,
    required this.photoId,
    required this.title,
    required this.episodeIndex,
    required this.pageCount,
  });
}
