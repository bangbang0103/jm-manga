import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/reader_progress.dart';
import '../../widgets/loading_indicator.dart';

class ReaderPageImage extends StatefulWidget {
  final int index;
  final ImageProvider imageProvider;
  final ScrollController scrollController;
  final ValueNotifier<int> visibilityTick;
  final double placeholderAspectRatio;
  final String loadingMessage;
  final String failedMessage;
  final ValueChanged<ReaderPageVisibility> onVisibilityChanged;
  final ValueChanged<double> onAspectRatioChanged;
  final VoidCallback onRetry;

  const ReaderPageImage({
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
  State<ReaderPageImage> createState() => _ReaderPageImageState();
}

class _ReaderPageImageState extends State<ReaderPageImage> {
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
  void didUpdateWidget(covariant ReaderPageImage oldWidget) {
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
        ReaderPageVisibility.hidden(
          widget.index,
          tick: widget.visibilityTick.value,
        ),
      );
      return;
    }

    if (!widget.scrollController.hasClients) {
      widget.onVisibilityChanged(
        ReaderPageVisibility.hidden(
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
        ReaderPageVisibility.hidden(
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
      ReaderPageVisibility(
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
