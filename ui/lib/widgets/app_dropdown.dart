import 'package:flutter/material.dart';

/// 统一风格的 DropdownMenu：圆角背景、最大菜单高度、可选输入过滤。
class AppDropdownMenu<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelFor;
  final Widget? Function(T)? leadingIconFor;
  final Widget? Function(T)? trailingIconFor;
  final ValueChanged<T?> onSelected;
  final bool requestFocusOnTap;
  final double? width;
  final String? label;

  const AppDropdownMenu({
    super.key,
    required this.value,
    required this.items,
    required this.labelFor,
    required this.onSelected,
    this.leadingIconFor,
    this.trailingIconFor,
    this.requestFocusOnTap = false,
    this.width,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DropdownMenu<T>(
      initialSelection: value,
      width: width,
      requestFocusOnTap: requestFocusOnTap,
      enableFilter: requestFocusOnTap,
      label: label != null ? Text(label!) : null,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      menuStyle: MenuStyle(
        visualDensity: VisualDensity.compact,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        maximumSize: const WidgetStatePropertyAll(Size(double.infinity, 360)),
      ),
      dropdownMenuEntries: items.map((item) {
        return DropdownMenuEntry<T>(
          value: item,
          label: labelFor(item),
          leadingIcon: leadingIconFor?.call(item),
          trailingIcon: trailingIconFor?.call(item),
          style: MenuItemButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        );
      }).toList(),
      onSelected: onSelected,
    );
  }
}
