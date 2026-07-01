import 'package:flutter/material.dart';

import 'tag_chip.dart';

enum _ChipType { keyword, include, exclude }

class FilterChipBar extends StatelessWidget {
  final String keywords;
  final List<String> includes;
  final List<String> excludes;
  final ValueChanged<String>? onRemoveKeyword;
  final ValueChanged<String>? onRemoveInclude;
  final ValueChanged<String>? onRemoveExclude;

  const FilterChipBar({
    super.key,
    this.keywords = '',
    this.includes = const <String>[],
    this.excludes = const <String>[],
    this.onRemoveKeyword,
    this.onRemoveInclude,
    this.onRemoveExclude,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = <Widget>[];

    final keyword = keywords.trim();
    if (keyword.isNotEmpty) {
      chips.add(
        _buildChip(
          context,
          type: _ChipType.keyword,
          label: keyword,
          onRemove: onRemoveKeyword != null
              ? () => onRemoveKeyword!(keyword)
              : null,
        ),
      );
    }

    for (final tag in includes) {
      chips.add(
        _buildChip(
          context,
          type: _ChipType.include,
          label: tag,
          onRemove: onRemoveInclude != null ? () => onRemoveInclude!(tag) : null,
        ),
      );
    }

    for (final tag in excludes) {
      chips.add(
        _buildChip(
          context,
          type: _ChipType.exclude,
          label: tag,
          onRemove: onRemoveExclude != null ? () => onRemoveExclude!(tag) : null,
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      color: theme.colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: chips),
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required _ChipType type,
    required String label,
    required VoidCallback? onRemove,
  }) {
    final (icon, variant) = switch (type) {
      _ChipType.keyword => (Icons.search, TagChipVariant.standard),
      _ChipType.include => (Icons.add, TagChipVariant.primary),
      _ChipType.exclude => (Icons.remove, TagChipVariant.error),
    };

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TagChip(
        label: label,
        icon: icon,
        variant: variant,
        onDelete: onRemove,
      ),
    );
  }
}
