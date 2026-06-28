import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/config_provider.dart';
import '../utils/custom_domain_utils.dart';
import '../utils/proxy_config.dart';
import '../utils/top_toast.dart';

class CustomDomainSettingsScreen extends ConsumerStatefulWidget {
  const CustomDomainSettingsScreen({super.key});

  @override
  ConsumerState<CustomDomainSettingsScreen> createState() =>
      _CustomDomainSettingsScreenState();
}

enum _DomainStatus { unknown, testing, success, failure }

class _DomainRow {
  final String url;
  _DomainStatus status = _DomainStatus.unknown;
  int? latencyMs;

  _DomainRow({required this.url});
}

class _CustomDomainSettingsScreenState
    extends ConsumerState<CustomDomainSettingsScreen> {
  late final List<_DomainRow> _apiRows;
  late final List<_DomainRow> _imageRows;
  bool _testingAll = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(configProvider);
    _apiRows = config.customApiDomains.map((u) => _DomainRow(url: u)).toList();
    _imageRows =
        config.customImageDomains.map((u) => _DomainRow(url: u)).toList();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    await ref.read(configProvider.notifier).setCustomApiDomains(
      _apiRows.map((r) => r.url).toList(),
    );
    await ref.read(configProvider.notifier).setCustomImageDomains(
      _imageRows.map((r) => r.url).toList(),
    );

    if (!mounted) return;
    TopToast.show(context, l10n.customDomainSaved, type: TopToastType.success);
  }

  Future<void> _clear() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _apiRows.clear();
      _imageRows.clear();
    });

    await ref.read(configProvider.notifier).setCustomApiDomains(
      const <String>[],
    );
    await ref.read(configProvider.notifier).setCustomImageDomains(
      const <String>[],
    );

    if (!mounted) return;
    TopToast.show(context, l10n.customDomainCleared, type: TopToastType.success);
  }

  Future<void> _showAddDialog({required bool isApi}) async {
    final l10n = AppLocalizations.of(context)!;
    final url = await showDialog<String>(
      context: context,
      builder: (context) => _AddDomainDialog(
        title: isApi ? l10n.customDomainApiLabel : l10n.customDomainImageLabel,
        hint: l10n.customDomainHint,
        addLabel: l10n.customDomainAddHint,
      ),
    );
    if (url == null || url.isEmpty) return;
    setState(() {
      if (isApi) {
        _apiRows.add(_DomainRow(url: url));
      } else {
        _imageRows.add(_DomainRow(url: url));
      }
    });
  }

  void _removeApiDomain(int index) {
    setState(() => _apiRows.removeAt(index));
  }

  void _removeImageDomain(int index) {
    setState(() => _imageRows.removeAt(index));
  }

  void _moveApiDomain(int index, int delta) {
    final newIndex = index + delta;
    if (newIndex < 0 || newIndex >= _apiRows.length) return;
    setState(() {
      final item = _apiRows.removeAt(index);
      _apiRows.insert(newIndex, item);
    });
  }

  void _moveImageDomain(int index, int delta) {
    final newIndex = index + delta;
    if (newIndex < 0 || newIndex >= _imageRows.length) return;
    setState(() {
      final item = _imageRows.removeAt(index);
      _imageRows.insert(newIndex, item);
    });
  }

  Future<int?> _measureLatency(String url, String? proxyUrl) async {
    final dio = Dio();
    configureDioProxy(dio, proxyUrl);
    dio.options = dio.options.copyWith(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      validateStatus: (status) => true,
    );
    final stopwatch = Stopwatch()..start();
    try {
      await dio.get(url);
      return stopwatch.elapsedMilliseconds;
    } on DioException {
      return null;
    } finally {
      dio.close();
    }
  }

  Future<void> _testAll() async {
    final l10n = AppLocalizations.of(context)!;
    final allRows = [..._apiRows, ..._imageRows];
    if (allRows.isEmpty) {
      TopToast.show(
        context,
        l10n.customDomainNoDomainToTest,
        type: TopToastType.error,
      );
      return;
    }

    setState(() {
      _testingAll = true;
      for (final row in allRows) {
        row.status = _DomainStatus.testing;
        row.latencyMs = null;
      }
    });

    final proxyUrl = ref.read(configProvider).proxyUrl;
    final futures = allRows.map((row) async {
      final latency = await _measureLatency(row.url, proxyUrl);
      if (!mounted) return;
      setState(() {
        row.latencyMs = latency;
        row.status = latency != null
            ? _DomainStatus.success
            : _DomainStatus.failure;
      });
    }).toList();

    await Future.wait(futures);

    if (!mounted) return;
    setState(() => _testingAll = false);

    final hasFailure = allRows.any((r) => r.status == _DomainStatus.failure);
    if (hasFailure) {
      TopToast.show(
        context,
        l10n.customDomainTestFailed,
        type: TopToastType.error,
      );
    } else {
      TopToast.show(
        context,
        l10n.customDomainTestSuccess,
        type: TopToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.customDomainTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoCard(subtitle: l10n.customDomainSubtitle),
              const SizedBox(height: 20),
              _DomainSection(
                label: l10n.customDomainApiLabel,
                emptyText: l10n.customDomainEmpty,
                icon: Icons.cloud_outlined,
                rows: _apiRows,
                onAdd: () => _showAddDialog(isApi: true),
                onRemove: _removeApiDomain,
                onMove: _moveApiDomain,
                latencyFormatter: (ms) => l10n.customDomainLatency('$ms'),
                latencyFailed: l10n.customDomainLatencyFailed,
                moveUpLabel: l10n.customDomainMoveUp,
                moveDownLabel: l10n.customDomainMoveDown,
                deleteLabel: l10n.customDomainDelete,
              ),
              const SizedBox(height: 20),
              _DomainSection(
                label: l10n.customDomainImageLabel,
                emptyText: l10n.customDomainEmpty,
                icon: Icons.image_outlined,
                rows: _imageRows,
                onAdd: () => _showAddDialog(isApi: false),
                onRemove: _removeImageDomain,
                onMove: _moveImageDomain,
                latencyFormatter: (ms) => l10n.customDomainLatency('$ms'),
                latencyFailed: l10n.customDomainLatencyFailed,
                moveUpLabel: l10n.customDomainMoveUp,
                moveDownLabel: l10n.customDomainMoveDown,
                deleteLabel: l10n.customDomainDelete,
              ),
              const SizedBox(height: 28),
              FilledButton.tonalIcon(
                onPressed: _testingAll ? null : _testAll,
                icon: _testingAll
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.network_ping_outlined),
                label: Text(l10n.customDomainTest),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _clear,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(l10n.actionClear),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check),
                      label: Text(l10n.actionSave),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String subtitle;

  const _InfoCard({required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DomainSection extends StatelessWidget {
  final String label;
  final String emptyText;
  final IconData icon;
  final List<_DomainRow> rows;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final void Function(int index, int delta) onMove;
  final String Function(int ms) latencyFormatter;
  final String latencyFailed;
  final String moveUpLabel;
  final String moveDownLabel;
  final String deleteLabel;

  const _DomainSection({
    required this.label,
    required this.emptyText,
    required this.icon,
    required this.rows,
    required this.onAdd,
    required this.onRemove,
    required this.onMove,
    required this.latencyFormatter,
    required this.latencyFailed,
    required this.moveUpLabel,
    required this.moveDownLabel,
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
            _CountBadge(count: rows.length),
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
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < rows.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _DomainCard(
                          row: rows[i],
                          index: i,
                          count: rows.length,
                          onRemove: () => onRemove(i),
                          onMoveUp: () => onMove(i, -1),
                          onMoveDown: () => onMove(i, 1),
                          latencyFormatter: latencyFormatter,
                          latencyFailed: latencyFailed,
                          moveUpLabel: moveUpLabel,
                          moveDownLabel: moveDownLabel,
                          deleteLabel: deleteLabel,
                        ),
                      ),
                  ],
                ),
        ),
      ],
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

class _AddDomainDialog extends StatefulWidget {
  final String title;
  final String hint;
  final String addLabel;

  const _AddDomainDialog({
    required this.title,
    required this.hint,
    required this.addLabel,
  });

  @override
  State<_AddDomainDialog> createState() => _AddDomainDialogState();
}

class _AddDomainDialogState extends State<_AddDomainDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    final result = CustomDomainUtils.parse(value);
    if (result.uri == null) {
      setState(() => _error = result.error ?? 'Invalid domain');
      return;
    }
    Navigator.of(context).pop(result.uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: widget.addLabel,
          hintText: widget.hint,
          errorText: _error,
          filled: true,
          fillColor: scheme.surfaceContainer,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: scheme.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: scheme.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: scheme.error, width: 1.5),
          ),
          prefixIcon: Icon(
            Icons.add_link_outlined,
            color: scheme.onSurfaceVariant,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.customDomainAddHint),
        ),
      ],
    );
  }
}

class _DomainCard extends StatelessWidget {
  final _DomainRow row;
  final int index;
  final int count;
  final VoidCallback onRemove;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final String Function(int ms) latencyFormatter;
  final String latencyFailed;
  final String moveUpLabel;
  final String moveDownLabel;
  final String deleteLabel;

  const _DomainCard({
    required this.row,
    required this.index,
    required this.count,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.latencyFormatter,
    required this.latencyFailed,
    required this.moveUpLabel,
    required this.moveDownLabel,
    required this.deleteLabel,
  });

  Color _latencyColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (row.status == _DomainStatus.failure) return scheme.error;
    final latency = row.latencyMs;
    if (latency == null) return scheme.onSurfaceVariant;
    if (latency < 300) return scheme.tertiary;
    if (latency < 800) return scheme.primary;
    return scheme.error;
  }

  String _latencyLabel() {
    if (row.status == _DomainStatus.failure) return latencyFailed;
    if (row.status == _DomainStatus.testing) return '...';
    final latency = row.latencyMs;
    if (latency == null) return '-';
    return latencyFormatter(latency);
  }

  (IconData, Color) _statusStyle(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (row.status) {
      _DomainStatus.testing => (
          Icons.pending_outlined,
          scheme.onSurfaceVariant,
        ),
      _DomainStatus.success => (
          Icons.check_circle_rounded,
          scheme.tertiary,
        ),
      _DomainStatus.failure => (
          Icons.error_rounded,
          scheme.error,
        ),
      _DomainStatus.unknown => (
          Icons.dns_outlined,
          scheme.onSurfaceVariant,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final displayUri = _displayUri(row.url);
    final (statusIcon, statusColor) = _statusStyle(context);
    final latencyColor = _latencyColor(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 14),
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
          _ActionMenu(
            canMoveUp: index > 0,
            canMoveDown: index < count - 1,
            onMoveUp: onMoveUp,
            onMoveDown: onMoveDown,
            onDelete: onRemove,
            moveUpLabel: moveUpLabel,
            moveDownLabel: moveDownLabel,
            deleteLabel: deleteLabel,
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

class _ActionMenu extends StatelessWidget {
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onDelete;
  final String moveUpLabel;
  final String moveDownLabel;
  final String deleteLabel;

  const _ActionMenu({
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
    required this.moveUpLabel,
    required this.moveDownLabel,
    required this.deleteLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<VoidCallback>(
      icon: Icon(
        Icons.more_vert,
        color: scheme.onSurfaceVariant,
      ),
      onSelected: (callback) => callback(),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: onMoveUp,
          enabled: canMoveUp,
          child: Row(
            children: [
              const Icon(Icons.arrow_upward, size: 20),
              const SizedBox(width: 10),
              Text(moveUpLabel),
            ],
          ),
        ),
        PopupMenuItem(
          value: onMoveDown,
          enabled: canMoveDown,
          child: Row(
            children: [
              const Icon(Icons.arrow_downward, size: 20),
              const SizedBox(width: 10),
              Text(moveDownLabel),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: onDelete,
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                size: 20,
                color: scheme.error,
              ),
              const SizedBox(width: 10),
              Text(
                deleteLabel,
                style: TextStyle(color: scheme.error),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
