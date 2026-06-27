import 'package:flutter/material.dart';

class RankingBadge extends StatelessWidget {
  final int rank;

  const RankingBadge({super.key, required this.rank});

  Color _color(ColorScheme scheme) {
    return switch (rank) {
      1 => scheme.tertiary, // Gold
      2 => scheme.surfaceContainerHighest, // Silver
      3 => scheme.secondary, // Bronze / coral
      _ => scheme.outline,
    };
  }

  Color _textColor(ColorScheme scheme) {
    return switch (rank) {
      1 => scheme.onTertiary,
      2 => scheme.onSurface,
      3 => scheme.onSecondary,
      _ => scheme.onSurface,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: _color(scheme), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: _textColor(scheme),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
