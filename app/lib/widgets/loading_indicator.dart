import 'package:flutter/material.dart';

/// 通用加载指示器，居中带可选提示文字。
class AppLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;

  const AppLoadingIndicator({super.key, this.message, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: size < 28 ? 2.5 : 3,
              color: theme.colorScheme.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 图片加载占位：带呼吸动效的渐变底、图标和可选文字。
class ImagePlaceholder extends StatefulWidget {
  final IconData icon;
  final String? message;

  const ImagePlaceholder({
    super.key,
    this.icon = Icons.image,
    this.message,
  });

  @override
  State<ImagePlaceholder> createState() => _ImagePlaceholderState();
}

class _ImagePlaceholderState extends State<ImagePlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        return Container(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: _opacity.value,
          ),
          child: child,
        );
      },
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: theme.colorScheme.primary,
              ),
            ),
            if (widget.message != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.message!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 图片加载失败占位。支持点击重试。
class ImageErrorPlaceholder extends StatelessWidget {
  final IconData icon;
  final String? message;
  final VoidCallback? onRetry;

  const ImageErrorPlaceholder({
    super.key,
    this.icon = Icons.broken_image,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 40,
          color: theme.colorScheme.onErrorContainer,
        ),
        if (message != null) ...[
          const SizedBox(height: 12),
          Text(
            message!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
        ],
      ],
    );

    return Container(
      color: theme.colorScheme.errorContainer,
      child: onRetry == null
          ? Center(child: content)
          : InkWell(
              onTap: onRetry,
              child: Center(child: content),
            ),
    );
  }
}
