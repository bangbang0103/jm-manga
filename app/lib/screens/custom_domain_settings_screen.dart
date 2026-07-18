import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/config_provider.dart';
import '../utils/proxy_config.dart';
import '../utils/top_toast.dart';
import '../widgets/beta_chip.dart';
import 'custom_domain/add_domain_dialog.dart';
import 'custom_domain/domain_row.dart';
import 'custom_domain/domain_section.dart';

class CustomDomainSettingsScreen extends ConsumerStatefulWidget {
  const CustomDomainSettingsScreen({super.key});

  @override
  ConsumerState<CustomDomainSettingsScreen> createState() =>
      _CustomDomainSettingsScreenState();
}

enum _LeaveAction { save, discard, cancel }

class _CustomDomainSettingsScreenState
    extends ConsumerState<CustomDomainSettingsScreen> {
  late final List<DomainRow> _apiRows;
  late final List<DomainRow> _imageRows;
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
    _apiRows = _savedApiUrls.map((u) => DomainRow(url: u)).toList();
    _imageRows = _savedImageUrls.map((u) => DomainRow(url: u)).toList();
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
      builder: (context) => AddDomainDialog(
        title: isApi ? l10n.customDomainApiLabel : l10n.customDomainImageLabel,
        hint: l10n.customDomainHint,
        addLabel: l10n.customDomainAddHint,
      ),
    );
    if (url == null || url.isEmpty) return;
    setState(() {
      if (isApi) {
        _apiRows.add(DomainRow(url: url));
      } else {
        _imageRows.add(DomainRow(url: url));
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
        row.status = DomainStatus.testing;
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
                  ? DomainStatus.success
                  : DomainStatus.failure;
            });
          } on DioException catch (e) {
            if (!CancelToken.isCancel(e)) {
              if (mounted) {
                setState(() => row.status = DomainStatus.failure);
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

    final hasFailure = allRows.any((r) => r.status == DomainStatus.failure);
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
                DomainSection(
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
                DomainSection(
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
