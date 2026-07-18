import 'package:flutter/material.dart';

import 'domain_row.dart';

class DomainCard extends StatelessWidget {
  final DomainRow row;
  final VoidCallback onRemove;
  final Widget dragHandle;
  final String Function(int ms) latencyFormatter;
  final String latencyFailed;
  final String deleteLabel;

  const DomainCard({
    super.key,
    required this.row,
    required this.onRemove,
    required this.dragHandle,
    required this.latencyFormatter,
    required this.latencyFailed,
    required this.deleteLabel,
  });

  Color _latencyColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (row.status == DomainStatus.failure) return scheme.error;
    final latency = row.latencyMs;
    if (latency == null) return scheme.onSurfaceVariant;
    if (latency < 300) return scheme.tertiary;
    if (latency < 800) return scheme.primary;
    return scheme.error;
  }

  String _latencyLabel() {
    if (row.status == DomainStatus.failure) return latencyFailed;
    if (row.status == DomainStatus.testing) return '...';
    final latency = row.latencyMs;
    if (latency == null) return '-';
    return latencyFormatter(latency);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final displayUri = _displayUri(row.url);
    final latencyColor = _latencyColor(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 14, 14, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Center(child: dragHandle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayUri.host,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _schemeAndPort(displayUri),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _LatencyChip(
            label: _latencyLabel(),
            color: latencyColor,
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.delete_outline, color: scheme.error),
            tooltip: deleteLabel,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }

  Uri _displayUri(String url) => Uri.parse(url);

  String _schemeAndPort(Uri uri) {
    if (uri.hasPort && uri.port != 443 && uri.port != 80) {
      return '${uri.scheme} • ${uri.port}';
    }
    return uri.scheme;
  }
}

class _LatencyChip extends StatelessWidget {
  final String label;
  final Color color;

  const _LatencyChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
