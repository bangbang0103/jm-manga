import 'package:flutter/material.dart';

import 'animated_favorite_button.dart';
import 'pressable.dart';
import 'retryable_image.dart';

class MangaCoverCard extends StatefulWidget {
  final String title;
  final ImageProvider imageProvider;
  final String? badgeText;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  const MangaCoverCard({
    super.key,
    required this.title,
    required this.imageProvider,
    this.badgeText,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
  });

  @override
  State<MangaCoverCard> createState() => _MangaCoverCardState();
}

class _MangaCoverCardState extends State<MangaCoverCard> {
  final _imageKey = GlobalKey<RetryableImageState>();
  bool _hasError = false;
  bool _isRetrying = false;

  void _onError() {
    if (mounted && !_hasError) {
      setState(() {
        _hasError = true;
        _isRetrying = false;
      });
    }
  }

  void _onLoad() {
    if (mounted && (_hasError || _isRetrying)) {
      setState(() {
        _hasError = false;
        _isRetrying = false;
      });
    }
  }

  void _retryImage() {
    if (_isRetrying) return;
    setState(() {
      _hasError = false;
      _isRetrying = true;
    });
    _imageKey.currentState?.retry();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: RetryableImage(
                  key: _imageKey,
                  imageProvider: widget.imageProvider,
                  fit: BoxFit.cover,
                  showRetryInPlaceholder: false,
                  onError: _onError,
                  onLoad: _onLoad,
                ),
              ),
            ),
            if (_isRetrying)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Text(
                widget.title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.badgeText != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.badgeText!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_hasError)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Material(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: _retryImage,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.refresh,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (widget.onFavorite != null)
                    Material(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedFavoriteButton(
                        isFavorite: widget.isFavorite,
                        onPressed: widget.onFavorite,
                        size: 20,
                        padding: const EdgeInsets.all(8),
                        color: theme.colorScheme.secondary,
                        inactiveColor: theme.colorScheme.onSurface,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.onTap != null) {
      card = Pressable(onTap: widget.onTap, child: card);
    }

    return card;
  }
}
