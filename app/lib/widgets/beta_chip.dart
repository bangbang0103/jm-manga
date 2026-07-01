import 'package:flutter/material.dart';

/// 用于标识 BETA 功能的小标签。
///
/// 使用与其他 tag chip 统一的圆角胶囊样式，字体缩小。
class BetaChip extends StatelessWidget {
  const BetaChip({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foregroundColor = colorScheme.onPrimaryContainer;

    return RawChip(
      label: Text(
        'BETA',
        style: theme.textTheme.labelSmall?.copyWith(
          color: foregroundColor,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
      backgroundColor: colorScheme.primaryContainer,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      shape: const StadiumBorder(),
      side: BorderSide.none,
    );
  }
}
