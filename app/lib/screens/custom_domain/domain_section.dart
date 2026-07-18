import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'domain_card.dart';
import 'domain_row.dart';

class DomainSection extends StatelessWidget {
  final String label;
  final String emptyText;
  final IconData icon;
  final List<DomainRow> rows;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;
  final String Function(int ms) latencyFormatter;
  final String latencyFailed;
  final String deleteLabel;

  const DomainSection({
    super.key,
    required this.label,
    required this.emptyText,
    required this.icon,
    required this.rows,
    required this.onAdd,
    required this.onRemove,
    required this.onReorder,
    required this.latencyFormatter,
    required this.latencyFailed,
    required this.deleteLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            if (rows.isNotEmpty) _CountBadge(count: rows.length),
            const Spacer(),
            FilledButton.tonal(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context)!.customDomainAddHint,
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: rows.isEmpty
              ? _EmptyState(text: emptyText)
              : _ReorderableDomainList(
                  rows: rows,
                  onRemove: onRemove,
                  onReorder: onReorder,
                  latencyFormatter: latencyFormatter,
                  latencyFailed: latencyFailed,
                  deleteLabel: deleteLabel,
                ),
        ),
      ],
    );
  }
}

class _ReorderableDomainList extends StatelessWidget {
  final List<DomainRow> rows;
  final void Function(int index) onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;
  final String Function(int ms) latencyFormatter;
  final String latencyFailed;
  final String deleteLabel;

  const _ReorderableDomainList({
    required this.rows,
    required this.onRemove,
    required this.onReorder,
    required this.latencyFormatter,
    required this.latencyFailed,
    required this.deleteLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: rows.length,
      onReorderItem: onReorder,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final elevationValue = Tween<double>(begin: 0, end: 6)
                .evaluate(animation);
            return Material(
              elevation: elevationValue,
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: child,
            );
          },
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final row = rows[index];
        return Padding(
          key: ValueKey(row.id),
          padding: const EdgeInsets.only(bottom: 10),
          child: DomainCard(
            row: row,
            onRemove: () => onRemove(index),
            dragHandle: ReorderableDragStartListener(
              index: index,
              child: Tooltip(
                message: AppLocalizations.of(context)!.customDomainDragToReorder,
                child: Icon(
                  Icons.reorder,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            latencyFormatter: latencyFormatter,
            latencyFailed: latencyFailed,
            deleteLabel: deleteLabel,
          ),
        );
      },
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: theme.textTheme.labelMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;

  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 160),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.dns_outlined,
            size: 40,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
