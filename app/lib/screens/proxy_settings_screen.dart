import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/config_provider.dart';
import '../utils/proxy_config.dart';
import '../utils/top_toast.dart';

class ProxySettingsScreen extends ConsumerStatefulWidget {
  const ProxySettingsScreen({super.key});

  @override
  ConsumerState<ProxySettingsScreen> createState() =>
      _ProxySettingsScreenState();
}

class _ProxySettingsScreenState extends ConsumerState<ProxySettingsScreen> {
  late final TextEditingController _controller;
  String? _error;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(configProvider).proxyUrl ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isValidProxy(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return true;
    Uri? uri;
    if (trimmed.contains('://')) {
      uri = Uri.tryParse(trimmed);
    } else {
      uri = Uri.tryParse('http://$trimmed');
    }
    return uri != null && uri.host.isNotEmpty && uri.port > 0;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final value = _controller.text.trim();

    if (!_isValidProxy(value)) {
      setState(() => _error = l10n.proxyInvalid);
      return;
    }
    setState(() => _error = null);

    await ref.read(configProvider.notifier).setProxyUrl(value);
    if (!mounted) return;
    TopToast.show(context, l10n.proxySaved, type: TopToastType.success);
  }

  Future<void> _clear() async {
    final l10n = AppLocalizations.of(context)!;
    _controller.clear();
    setState(() => _error = null);
    await ref.read(configProvider.notifier).setProxyUrl(null);
    if (!mounted) return;
    TopToast.show(context, l10n.proxyCleared, type: TopToastType.success);
  }

  Future<void> _test() async {
    final l10n = AppLocalizations.of(context)!;
    final value = _controller.text.trim();

    if (!_isValidProxy(value)) {
      setState(() => _error = l10n.proxyInvalid);
      return;
    }
    setState(() {
      _error = null;
      _testing = true;
    });

    final reachable = await testProxyConnection(value);

    if (!mounted) return;
    setState(() => _testing = false);

    if (reachable) {
      TopToast.show(context, l10n.proxyReachable, type: TopToastType.success);
    } else {
      TopToast.show(context, l10n.proxyUnreachable, type: TopToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final current = ref.watch(configProvider).proxyUrl;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.proxyTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.proxyTitle, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text(
                      l10n.proxySubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        labelText: l10n.proxyTitle,
                        hintText: l10n.proxyHint,
                        errorText: _error,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _save(),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.proxyProtocolHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (current != null && current.isNotEmpty)
              Text(
                '${l10n.proxyTitle}: $current',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const Spacer(),
            FilledButton.tonal(
              onPressed: _testing ? null : _test,
              child: _testing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.proxyTest),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clear,
                    child: Text(l10n.actionClear),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(l10n.actionSave),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
