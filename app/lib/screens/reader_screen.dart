import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/manga_repository.dart';
import '../data/direct_manga_repository.dart';
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
  final ValueNotifier<int> _visibilityTick = ValueNotifier<int>(0);
  late final MangaRepository _repo;
  int _lastPreloadedIndex = -1;
  int _lastPreloadedTargetWidth = 0;
  bool _visibilityCheckScheduled = false;
  String? _pageStatePhotoId;
  String? _resumeAppliedForPhotoId;
  int _resumeAttempts = 0;
  static const double _fallbackAspectRatio = 0.7;
  double _fallbackItemExtent = 400;
  List<double> _estimatedItemExtents = const [];
  final Map<String, double> _imageAspectRatios = {};
  final Map<String, int> _imageRetryCounts = {};
  final Map<int, _ReaderPageVisibility> _visiblePages = {};

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
    _visibilityTick.dispose();
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
    context.replace('/reader/$photoId', extra: initialData);
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
    // 先按已知图片比例估算偏移量，等下一帧再尝试 ensureVisible。
    if (_scrollController.hasClients && _resumeAttempts < 20) {
      _resumeAttempts += 1;
      final targetOffset = _estimatedOffsetForIndex(index);
      final maxOffset = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(targetOffset.clamp(0.0, maxOffset).toDouble());
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
    if (_currentIndex == _lastPreloadedIndex &&
        targetImageWidth == _lastPreloadedTargetWidth) {
      return;
    }
    _lastPreloadedIndex = _currentIndex;
    _lastPreloadedTargetWidth = targetImageWidth;
    if (urls.isEmpty) return;
    if (targetImageWidth <= 0) return;
    final start = _currentIndex.clamp(0, urls.length - 1).toInt();
    final end = preloadCount <= 0
        ? start
        : (_currentIndex + preloadCount).clamp(0, urls.length - 1).toInt();
    for (int i = start; i <= end; i++) {
      final url = urls[i];
      unawaited(
        precacheImage(
          ResizeImage(_repo.imageProvider(url), width: targetImageWidth),
          context,
        ).catchError((_) {}),
      );
    }
  }

  void _setCurrentIndex(int index, {required int pageCount}) {
    if (pageCount <= 0) return;
    final safeIndex = index.clamp(0, pageCount - 1).toInt();
    if (safeIndex == _currentIndex) return;
    setState(() {
      _currentIndex = safeIndex;
      if (_currentIndex >= pageCount - 1) {
        _hasFinished = true;
      }
    });
    _scheduleSync();
  }

  void _scheduleVisibilityCheck() {
    if (_visibilityCheckScheduled) return;
    _visibilityCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _visibilityCheckScheduled = false;
      _visibilityTick.value += 1;
    });
  }

  void _handlePageVisibilityChanged(
    _ReaderPageVisibility visibility, {
    required int pageCount,
  }) {
    if (pageCount <= 0 ||
        visibility.index < 0 ||
        visibility.index >= pageCount) {
      return;
    }
    if (visibility.visiblePixels <= 0) {
      _visiblePages.remove(visibility.index);
    } else {
      _visiblePages[visibility.index] = visibility;
    }

    final index = _currentIndexFromVisibility(pageCount);
    if (index != null) {
      _setCurrentIndex(index, pageCount: pageCount);
    }
  }

  int? _currentIndexFromVisibility(int pageCount) {
    final currentTick = _visibilityTick.value;
    final visible = _visiblePages.values
        .where(
          (v) =>
              v.tick == currentTick &&
              v.index >= 0 &&
              v.index < pageCount &&
              v.visiblePixels > 0,
        )
        .toList();
    if (visible.isEmpty) return null;

    visible.sort((a, b) {
      if (a.containsViewportCenter != b.containsViewportCenter) {
        return a.containsViewportCenter ? -1 : 1;
      }
      if (a.containsViewportCenter && b.containsViewportCenter) {
        final centerCompare = a.centerDistance.compareTo(b.centerDistance);
        if (centerCompare != 0) return centerCompare;
      } else {
        final visibleCompare = b.visiblePixels.compareTo(a.visiblePixels);
        if (visibleCompare != 0) return visibleCompare;
        final centerCompare = a.centerDistance.compareTo(b.centerDistance);
        if (centerCompare != 0) return centerCompare;
      }
      return a.index.compareTo(b.index);
    });

    return visible.first.index;
  }

  void _updateEstimatedItemExtents(List<String> urls, double viewportWidth) {
    if (viewportWidth <= 0) return;
    _fallbackItemExtent = viewportWidth / _fallbackAspectRatio;
    _estimatedItemExtents = [
      for (final url in urls)
        viewportWidth / (_imageAspectRatios[url] ?? _fallbackAspectRatio),
    ];
  }

  double _estimatedOffsetForIndex(int index) {
    if (index <= 0) return 0;
    if (_estimatedItemExtents.isEmpty) {
      return index * _fallbackItemExtent;
    }

    var offset = 0.0;
    final safeIndex = index.clamp(0, _estimatedItemExtents.length).toInt();
    for (var i = 0; i < safeIndex; i++) {
      offset += _estimatedItemExtents[i];
    }
    return offset;
  }

  void _handleImageAspectRatio(String url, double aspectRatio) {
    if (!mounted || !aspectRatio.isFinite || aspectRatio <= 0) return;
    final previous = _imageAspectRatios[url];
    if (previous != null && (previous - aspectRatio).abs() < 0.001) return;
    setState(() {
      _imageAspectRatios[url] = aspectRatio;
    });
    _scheduleVisibilityCheck();
  }

  void _preparePageState(PhotoDetail photo) {
    if (_pageStatePhotoId == photo.photoId &&
        _imageKeys.length == photo.imageUrls.length) {
      return;
    }

    _pageStatePhotoId = photo.photoId;
    _visiblePages.clear();
    _imageKeys
      ..clear()
      ..addAll(List.generate(photo.imageUrls.length, (_) => GlobalKey()));
    _lastPreloadedIndex = -1;
    _lastPreloadedTargetWidth = 0;
    if (_resumeAppliedForPhotoId != photo.photoId) {
      _currentIndex = 0;
      _hasFinished = false;
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
    final needsAlbum =
        photoAlbumId != null &&
        (initialData == null || initialData.album.albumId != photoAlbumId);
    final albumAsync = needsAlbum
        ? ref.watch(albumDetailProvider(photoAlbumId))
        : null;
    final showAppBar =
        photoAsync.isLoading ||
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
            ? AppBar(leading: const BackButton(), title: Text(appBarTitle))
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
            onRetry: () => ref.invalidate(photoDetailProvider(widget.photoId)),
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
    final targetImageWidth = (screenWidth * mediaQuery.devicePixelRatio)
        .toInt();
    // 以常见竖版漫画宽高比 0.7 做初始估算；图片加载后会用真实比例修正。
    _updateEstimatedItemExtents(photo.imageUrls, screenWidth);
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

    _preparePageState(photo);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadImages(
        photo.imageUrls,
        preloadCount: preloadCount,
        targetImageWidth: targetImageWidth,
      );
      if (mounted) _visibilityTick.value += 1;
    });

    return GestureDetector(
      onTap: () => _toolbarVisible.value = !_toolbarVisible.value,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification ||
                  notification is ScrollEndNotification ||
                  notification is UserScrollNotification) {
                _scheduleVisibilityCheck();
              }
              return false;
            },
            child: ListView.builder(
              controller: _scrollController,
              itemCount: photo.imageUrls.length,
              itemBuilder: (context, index) {
                final url = photo.imageUrls[index];
                final retryCount = _imageRetryCounts[url] ?? 0;
                final imageProvider = ResizeImage(
                  _repo.imageProvider(url),
                  width: targetImageWidth,
                );
                final placeholderAspectRatio =
                    _imageAspectRatios[url] ?? _fallbackAspectRatio;
                return GestureDetector(
                  key: _imageKeys[index],
                  onLongPress: () => showImageDownloadSheet(
                    context,
                    ref,
                    url: url,
                    fallbackName: '${widget.photoId}_$index.jpg',
                  ),
                  behavior: HitTestBehavior.translucent,
                  child: _ReaderPageImage(
                    key: ValueKey('reader_image_${url}_$retryCount'),
                    index: index,
                    imageProvider: imageProvider,
                    scrollController: _scrollController,
                    visibilityTick: _visibilityTick,
                    placeholderAspectRatio: placeholderAspectRatio,
                    loadingMessage: l10n.imageLoading,
                    failedMessage: l10n.imageLoadFailed,
                    onVisibilityChanged: (visibility) =>
                        _handlePageVisibilityChanged(
                          visibility,
                          pageCount: photo.imageUrls.length,
                        ),
                    onAspectRatioChanged: (aspectRatio) =>
                        _handleImageAspectRatio(url, aspectRatio),
                    onRetry: () {
                      if (_repo is DirectMangaRepository) {
                        _repo.imageService.clearBackoff();
                      }
                      setState(() {
                        _imageRetryCounts[url] = retryCount + 1;
                      });
                    },
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
                                      onPressed: () => _openChapter(
                                        prevPhotoId,
                                        initialData,
                                      ),
                                    )
                                  else
                                    const SizedBox(width: 48),
                                  const SizedBox(width: 24),
                                  if (_hasFinished)
                                    Chip(
                                      label: Text(l10n.finishedBadge),
                                      backgroundColor: theme
                                          .colorScheme
                                          .surfaceContainerHigh,
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
                                      onPressed: () => _openChapter(
                                        nextPhotoId,
                                        initialData,
                                      ),
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

class _ReaderPageImage extends StatefulWidget {
  final int index;
  final ImageProvider imageProvider;
  final ScrollController scrollController;
  final ValueNotifier<int> visibilityTick;
  final double placeholderAspectRatio;
  final String loadingMessage;
  final String failedMessage;
  final ValueChanged<_ReaderPageVisibility> onVisibilityChanged;
  final ValueChanged<double> onAspectRatioChanged;
  final VoidCallback onRetry;

  const _ReaderPageImage({
    super.key,
    required this.index,
    required this.imageProvider,
    required this.scrollController,
    required this.visibilityTick,
    required this.placeholderAspectRatio,
    required this.loadingMessage,
    required this.failedMessage,
    required this.onVisibilityChanged,
    required this.onAspectRatioChanged,
    required this.onRetry,
  });

  @override
  State<_ReaderPageImage> createState() => _ReaderPageImageState();
}

class _ReaderPageImageState extends State<_ReaderPageImage> {
  late final ImageStreamListener _listener;
  ImageStream? _imageStream;
  bool _visibilityReportScheduled = false;

  @override
  void initState() {
    super.initState();
    _listener = ImageStreamListener(_handleImage, onError: (_, _) {});
    widget.visibilityTick.addListener(_scheduleVisibilityReport);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
    _scheduleVisibilityReport();
  }

  @override
  void didUpdateWidget(covariant _ReaderPageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageProvider != oldWidget.imageProvider) {
      _resolveImage();
    }
    if (widget.visibilityTick != oldWidget.visibilityTick) {
      oldWidget.visibilityTick.removeListener(_scheduleVisibilityReport);
      widget.visibilityTick.addListener(_scheduleVisibilityReport);
    }
    if (widget.index != oldWidget.index ||
        widget.scrollController != oldWidget.scrollController) {
      _scheduleVisibilityReport();
    }
  }

  @override
  void dispose() {
    widget.visibilityTick.removeListener(_scheduleVisibilityReport);
    _imageStream?.removeListener(_listener);
    super.dispose();
  }

  void _resolveImage() {
    _imageStream?.removeListener(_listener);
    _imageStream = widget.imageProvider.resolve(
      createLocalImageConfiguration(context),
    )..addListener(_listener);
  }

  void _handleImage(ImageInfo imageInfo, bool synchronousCall) {
    final width = imageInfo.image.width.toDouble();
    final height = imageInfo.image.height.toDouble();
    if (height <= 0) return;
    final aspectRatio = width / height;
    if (synchronousCall) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onAspectRatioChanged(aspectRatio);
        _scheduleVisibilityReport();
      });
      return;
    }
    widget.onAspectRatioChanged(aspectRatio);
    _scheduleVisibilityReport();
  }

  void _scheduleVisibilityReport() {
    if (_visibilityReportScheduled) return;
    _visibilityReportScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityReportScheduled = false;
      if (!mounted) return;
      _reportVisibility();
    });
  }

  void _reportVisibility() {
    final itemObject = context.findRenderObject();
    if (itemObject is! RenderBox ||
        !itemObject.attached ||
        !itemObject.hasSize) {
      widget.onVisibilityChanged(
        _ReaderPageVisibility.hidden(
          widget.index,
          tick: widget.visibilityTick.value,
        ),
      );
      return;
    }

    if (!widget.scrollController.hasClients) {
      widget.onVisibilityChanged(
        _ReaderPageVisibility.hidden(
          widget.index,
          tick: widget.visibilityTick.value,
        ),
      );
      return;
    }

    final viewportObject = widget
        .scrollController
        .position
        .context
        .storageContext
        .findRenderObject();
    if (viewportObject is! RenderBox ||
        !viewportObject.attached ||
        !viewportObject.hasSize) {
      widget.onVisibilityChanged(
        _ReaderPageVisibility.hidden(
          widget.index,
          tick: widget.visibilityTick.value,
        ),
      );
      return;
    }

    final itemTop = itemObject.localToGlobal(Offset.zero).dy;
    final itemBottom = itemTop + itemObject.size.height;
    final itemCenter = (itemTop + itemBottom) / 2;
    final viewportTop = viewportObject.localToGlobal(Offset.zero).dy;
    final viewportBottom = viewportTop + viewportObject.size.height;
    final viewportCenter = (viewportTop + viewportBottom) / 2;
    final visibleTop = math.max(itemTop, viewportTop);
    final visibleBottom = math.min(itemBottom, viewportBottom);
    final visiblePixels = math.max(0.0, visibleBottom - visibleTop);

    widget.onVisibilityChanged(
      _ReaderPageVisibility(
        index: widget.index,
        tick: widget.visibilityTick.value,
        visiblePixels: visiblePixels,
        centerDistance: (itemCenter - viewportCenter).abs(),
        containsViewportCenter:
            viewportCenter >= itemTop && viewportCenter <= itemBottom,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Image(
      image: widget.imageProvider,
      width: double.infinity,
      fit: BoxFit.fitWidth,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return AspectRatio(
          aspectRatio: widget.placeholderAspectRatio,
          child: ImagePlaceholder(message: widget.loadingMessage),
        );
      },
      errorBuilder: (_, _, _) => AspectRatio(
        aspectRatio: widget.placeholderAspectRatio,
        child: ImageErrorPlaceholder(
          message: widget.failedMessage,
          onRetry: widget.onRetry,
        ),
      ),
    );
  }
}

class _ReaderPageVisibility {
  final int index;
  final int tick;
  final double visiblePixels;
  final double centerDistance;
  final bool containsViewportCenter;

  const _ReaderPageVisibility({
    required this.index,
    required this.tick,
    required this.visiblePixels,
    required this.centerDistance,
    required this.containsViewportCenter,
  });

  factory _ReaderPageVisibility.hidden(int index, {required int tick}) {
    return _ReaderPageVisibility(
      index: index,
      tick: tick,
      visiblePixels: 0,
      centerDistance: double.infinity,
      containsViewportCenter: false,
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
