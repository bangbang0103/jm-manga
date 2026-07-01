import 'package:flutter/material.dart';

import 'loading_indicator.dart';

/// 支持加载失败时重试的图片组件。
///
/// 内部维护一个重试计数，重试时会让 Flutter 重建 [Image] 从而重新发起请求。
/// 可通过 [onError] / [onLoad] 把加载状态暴露给父组件，由父组件决定重试入口。
class RetryableImage extends StatefulWidget {
  final ImageProvider imageProvider;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool showRetryInPlaceholder;
  final VoidCallback? onError;
  final VoidCallback? onLoad;

  const RetryableImage({
    super.key,
    required this.imageProvider,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.showRetryInPlaceholder = true,
    this.onError,
    this.onLoad,
  });

  @override
  State<RetryableImage> createState() => RetryableImageState();
}

class RetryableImageState extends State<RetryableImage> {
  int _retryCount = 0;

  void retry() {
    PaintingBinding.instance.imageCache.evict(widget.imageProvider);
    setState(() {
      _retryCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final image = Image(
      key: ValueKey('${_retryCount}_${widget.imageProvider}'),
      image: widget.imageProvider,
      fit: widget.fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          if (widget.onLoad != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) widget.onLoad!();
            });
          }
          return child;
        }
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        if (widget.onError != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onError!();
          });
        }
        final placeholder = ImageErrorPlaceholder(
          onRetry: widget.showRetryInPlaceholder ? retry : null,
        );
        if (widget.showRetryInPlaceholder) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: retry,
            child: SizedBox.expand(child: placeholder),
          );
        }
        return SizedBox.expand(child: placeholder);
      },
    );

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: image,
    );
  }
}
