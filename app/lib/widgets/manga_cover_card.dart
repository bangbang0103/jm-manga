import 'package:flutter/material.dart';

import 'animated_favorite_button.dart';
import 'loading_indicator.dart';
import 'pressable.dart';

class MangaCoverCard extends StatelessWidget {
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
                child: Image(
                  image: imageProvider,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const ImagePlaceholder();
                  },
                  errorBuilder: (_, _, _) => const ImageErrorPlaceholder(),
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
                    badgeText!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            if (onFavorite != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: Material(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedFavoriteButton(
                    isFavorite: isFavorite,
                    onPressed: onFavorite,
                    size: 20,
                    padding: const EdgeInsets.all(8),
                    color: theme.colorScheme.secondary,
                    inactiveColor: theme.colorScheme.onSurface,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      card = Pressable(onTap: onTap, child: card);
    }

    return card;
  }
}
