import 'dart:async';

import 'package:flutter/material.dart';

enum TopToastType { info, success, error }

class TopToast {
  static OverlayEntry? _current;
  static Timer? _timer;

  static void show(
    BuildContext context,
    String message, {
    TopToastType type = TopToastType.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(context);
    _timer?.cancel();
    _current?.remove();

    final theme = Theme.of(context);
    final (icon, backgroundColor, foregroundColor) = _style(theme, type);

    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          child: Center(
            child: _ToastCard(
              message: message,
              icon: icon,
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
            ),
          ),
        ),
      ),
    );

    _current = entry;
    overlay.insert(entry);

    _timer = Timer(duration, () {
      entry.remove();
      if (_current == entry) _current = null;
    });
  }

  static (IconData, Color, Color) _style(ThemeData theme, TopToastType type) {
    return switch (type) {
      TopToastType.success => (
        Icons.check_circle_rounded,
        theme.colorScheme.primaryContainer,
        theme.colorScheme.onPrimaryContainer,
      ),
      TopToastType.error => (
        Icons.error_rounded,
        theme.colorScheme.errorContainer,
        theme.colorScheme.onErrorContainer,
      ),
      TopToastType.info => (
        Icons.info_rounded,
        theme.colorScheme.surfaceContainerHigh,
        theme.colorScheme.onSurface,
      ),
    };
  }
}

class _ToastCard extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  const _ToastCard({
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(top: 12, left: 16, right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 20, color: widget.foregroundColor),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  widget.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: widget.foregroundColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
