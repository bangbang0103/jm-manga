import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_shadows.dart';
import 'animated_favorite_button.dart';
import 'loading_indicator.dart';
import 'pressable.dart';

class MangaCoverCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final Map<String, String> imageHeaders;
  final String? badgeText;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  const MangaCoverCard({
    super.key,
    required this.title,
    required this.imageUrl,
    this.imageHeaders = const {},
    this.badgeText,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content = AspectRatio(
      aspectRatio: 2 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      httpHeaders: imageHeaders,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const ImagePlaceholder(),
                      errorWidget: (context, url, error) =>
                          const ImageErrorPlaceholder(),
                    )
                  : const Icon(Icons.image),
            ),
            Container(
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
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badgeText != null)
              Positioned(
                top: 8,
                right: 8,
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
                    badgeText!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      content = Pressable(
        onTap: onTap,
        child: content,
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Stack(
        children: [
          content,
          if (onFavorite != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(24),
                child: AnimatedFavoriteButton(
                  isFavorite: isFavorite,
                  onPressed: onFavorite,
                  size: 24,
                  padding: const EdgeInsets.all(12),
                  color: theme.colorScheme.secondary,
                  inactiveColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
