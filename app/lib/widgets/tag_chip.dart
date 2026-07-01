import 'package:flutter/material.dart';

/// 全局统一的 tag chip 样式。
///
/// 支持可选的前置图标、点击和删除回调，所有变体都使用圆角胶囊形状。
enum TagChipVariant { standard, primary, error }

class TagChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final TagChipVariant variant;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TagChip({
    super.key,
    required this.label,
    this.icon,
    this.variant = TagChipVariant.standard,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (backgroundColor, foregroundColor) = switch (variant) {
      TagChipVariant.standard => (
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurface,
      ),
      TagChipVariant.primary => (
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
      ),
      TagChipVariant.error => (
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
      ),
    };

    return RawChip(
      avatar: icon != null
          ? Icon(icon, size: 16, color: foregroundColor)
          : null,
      label: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(color: foregroundColor),
      ),
      backgroundColor: backgroundColor,
      deleteIcon: onDelete != null
          ? Icon(Icons.close, size: 16, color: foregroundColor)
          : null,
      deleteIconColor: foregroundColor,
      onDeleted: onDelete,
      onPressed: onTap,
      tapEnabled: onTap != null,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: const StadiumBorder(),
      side: BorderSide(color: foregroundColor.withValues(alpha: 0.12)),
    );
  }
}
