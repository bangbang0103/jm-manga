import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/config_provider.dart';
import '../utils/custom_domain_utils.dart';
import '../utils/proxy_config.dart';
import '../utils/top_toast.dart';
import '../widgets/beta_chip.dart';

class CustomDomainSettingsScreen extends ConsumerStatefulWidget {
  const CustomDomainSettingsScreen({super.key});

  @override
  ConsumerState<CustomDomainSettingsScreen> createState() =>
      _CustomDomainSettingsScreenState();
}

enum _DomainStatus { unknown, testing, success, failure }

enum _LeaveAction { save, discard, cancel }

class _DomainRow {
  static int _idCounter = 0;
  final String id;
  final String url;
  _DomainStatus status = _DomainStatus.unknown;
  int? latencyMs;

  _DomainRow({required this.url}) : id = 'domain_${_idCounter++}';
}

class _CustomDomainSettingsScreenState
    extends ConsumerState<CustomDomainSettingsScreen> {
  late final List<_DomainRow> _apiRows;
  late final List<_DomainRow> _imageRows;
  late List<String> _savedApiUrls;
  late List<String> _savedImageUrls;
  bool _testingAll = false;
  CancelToken? _testCancelToken;

  @override
  void initState() {
    super.initState();
    final config = ref.read(configProvider);
    _savedApiUrls = List<String>.from(config.customApiDomains);
    _savedImageUrls = List<String>.from(config.customImageDomains);
    _apiRows = _savedApiUrls.map((u) => _DomainRow(url: u)).toList();
    _imageRows = _savedImageUrls.map((u) => _DomainRow(url: u)).toList();
  }

  bool get _isDirty {
    return !_urlListsEqual(
          _apiRows.map((r) => r.url).toList(),
          _savedApiUrls,
        ) ||
        !_urlListsEqual(
          _imageRows.map((r) => r.url).toList(),
          _savedImageUrls,
        );
  }

  bool _urlListsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _updateSavedUrls() {
    setState(() {
      _savedApiUrls = _apiRows.map((r) => r.url).toList();
      _savedImageUrls = _imageRows.map((r) => r.url).toList();
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final apiUrls = _apiRows.map((r) => r.url).toList();
    final imageUrls = _imageRows.map((r) => r.url).toList();
    await ref.read(configProvider.notifier).setCustomApiDomains(apiUrls);
    await ref.read(configProvider.notifier).setCustomImageDomains(imageUrls);

    if (!mounted) return;
    _updateSavedUrls();
    TopToast.show(context, l10n.customDomainSaved, type: TopToastType.success);
  }

  Future<bool> _confirmClear() async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmClearDomainsTitle),
        content: Text(l10n.confirmClearDomainsBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: Text(l10n.clearAll),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _clear() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirmClear();
    if (!confirmed) return;

    setState(() {
      _apiRows.clear();
      _imageRows.clear();
    });

    await ref.read(configProvider.notifier).setCustomApiDomains(const <String>[]);
    await ref
        .read(configProvider.notifier)
        .setCustomImageDomains(const <String>[]);

    if (!mounted) return;
    _updateSavedUrls();
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

  Future<bool> _confirmRemove(String domainUrl) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmDeleteDomainTitle),
        content: Text(l10n.confirmDeleteDomainBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _removeApiDomain(int index) async {
    final row = _apiRows[index];
    final confirmed = await _confirmRemove(row.url);
    if (!confirmed) return;
    setState(() => _apiRows.removeAt(index));
  }

  Future<void> _removeImageDomain(int index) async {
    final row = _imageRows[index];
    final confirmed = await _confirmRemove(row.url);
    if (!confirmed) return;
    setState(() => _imageRows.removeAt(index));
  }

  void _reorderApiDomain(int oldIndex, int newIndex) {
    setState(() {
      final item = _apiRows.removeAt(oldIndex);
      _apiRows.insert(newIndex, item);
    });
  }

  void _reorderImageDomain(int oldIndex, int newIndex) {
    setState(() {
      final item = _imageRows.removeAt(oldIndex);
      _imageRows.insert(newIndex, item);
    });
  }

  Future<int?> _measureLatency(
    String url,
    String? proxyUrl,
    CancelToken? cancelToken,
  ) async {
    final dio = Dio();
    configureDioProxy(dio, proxyUrl);
    dio.options = dio.options.copyWith(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      validateStatus: (status) => true,
    );
    final stopwatch = Stopwatch()..start();
    try {
      await dio.get(url, cancelToken: cancelToken);
      return stopwatch.elapsedMilliseconds;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
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
    _testCancelToken = CancelToken();
    final cancelToken = _testCancelToken;

    try {
      await Future.wait(
        allRows.map((row) async {
          try {
            final latency = await _measureLatency(row.url, proxyUrl, cancelToken);
            if (!mounted) return;
            if (cancelToken?.isCancelled ?? false) return;
            setState(() {
              row.latencyMs = latency;
              row.status = latency != null
                  ? _DomainStatus.success
                  : _DomainStatus.failure;
            });
          } on DioException catch (e) {
            if (!CancelToken.isCancel(e)) {
              if (mounted) {
                setState(() => row.status = _DomainStatus.failure);
              }
            }
          }
        }),
      );
    } on DioException catch (e) {
      if (!CancelToken.isCancel(e)) rethrow;
    } finally {
      if (mounted) {
        setState(() => _testingAll = false);
      }
      _testCancelToken = null;
    }

    if (!mounted) return;
    if (cancelToken?.isCancelled ?? false) return;

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

  void _stopTest() {
    _testCancelToken?.cancel();
  }

  Future<void> _handleLeave() async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final action = await showDialog<_LeaveAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.saveBeforeLeavingTitle),
        content: Text(l10n.saveBeforeLeavingBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_LeaveAction.cancel),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_LeaveAction.discard),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
            ),
            child: Text(l10n.discardChanges),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(_LeaveAction.save),
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );

    if (action == _LeaveAction.save) {
      await _save();
      if (mounted) Navigator.of(context).pop();
    } else if (action == _LeaveAction.discard) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _testCancelToken?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDirty = _isDirty;

    return PopScope(
      canPop: !isDirty && !_testingAll,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.customDomainTitle),
              const SizedBox(width: 8),
              const BetaChip(),
            ],
          ),
        ),
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
                  onReorder: _reorderApiDomain,
                  latencyFormatter: (ms) => l10n.customDomainLatency('$ms'),
                  latencyFailed: l10n.customDomainLatencyFailed,
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
                  onReorder: _reorderImageDomain,
                  latencyFormatter: (ms) => l10n.customDomainLatency('$ms'),
                  latencyFailed: l10n.customDomainLatencyFailed,
                  deleteLabel: l10n.customDomainDelete,
                ),
                const SizedBox(height: 28),
                if (_testingAll)
                  OutlinedButton.icon(
                    onPressed: _stopTest,
                    icon: const Icon(Icons.stop),
                    label: Text(l10n.actionStop),
                  )
                else
                  FilledButton.tonalIcon(
                    onPressed: _testAll,
                    icon: const Icon(Icons.network_ping_outlined),
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
                if (isDirty) ...[
                  const SizedBox(height: 12),
                  _UnsavedBanner(message: l10n.unsavedChangesHint),
                ],
                const SizedBox(height: 16),
              ],
            ),
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
  final void Function(int oldIndex, int newIndex) onReorder;
  final String Function(int ms) latencyFormatter;
  final String latencyFailed;
  final String deleteLabel;

  const _DomainSection({
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
  final List<_DomainRow> rows;
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
          child: _DomainCard(
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

class _UnsavedBanner extends StatelessWidget {
  final String message;

  const _UnsavedBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: scheme.onPrimaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
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
  final VoidCallback onRemove;
  final Widget dragHandle;
  final String Function(int ms) latencyFormatter;
  final String latencyFailed;
  final String deleteLabel;

  const _DomainCard({
    required this.row,
    required this.onRemove,
    required this.dragHandle,
    required this.latencyFormatter,
    required this.latencyFailed,
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


