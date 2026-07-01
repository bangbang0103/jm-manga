import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../providers/config_provider.dart';
import '../utils/app_logger.dart';
import '../widgets/beta_chip.dart';

class SettingsAdvancedScreen extends ConsumerWidget {
  const SettingsAdvancedScreen({super.key});

  Future<void> _showLogLevelSheet(
    BuildContext context,
    WidgetRef ref,
    LogLevel current,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final selected = await showModalBottomSheet<LogLevel>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.settingsLogLevelTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              ...LogLevel.values.map((level) {
                final selected = level == current;
                return ListTile(
                  title: Text(_levelLabel(l10n, level)),
                  trailing: selected
                      ? Icon(Icons.check, color: theme.colorScheme.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(level),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      await ref.read(configProvider.notifier).setLogLevel(selected);
    }
  }

  String _levelLabel(AppLocalizations l10n, LogLevel level) {
    return switch (level) {
      LogLevel.debug => l10n.logLevelDebug,
      LogLevel.info => l10n.logLevelInfo,
      LogLevel.warning => l10n.logLevelWarning,
      LogLevel.error => l10n.logLevelError,
    };
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final config = ref.watch(configProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.advancedSettingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.advancedSettingsDescription,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            context: context,
            title: l10n.advancedNetworkGroup,
            children: [
              ListTile(
                leading: const Icon(Icons.network_ping_outlined),
                title: Text(l10n.advancedProxyTitle),
                subtitle: Text(l10n.advancedProxySubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/proxy'),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.dns_outlined),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: Text(l10n.customDomainTitle)),
                    const SizedBox(width: 8),
                    const BetaChip(),
                  ],
                ),
                subtitle: Text(
                  (config.customApiDomains.isNotEmpty ||
                          config.customImageDomains.isNotEmpty)
                      ? l10n.customDomainEnabled
                      : l10n.customDomainDisabled,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/custom-domain'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            context: context,
            title: l10n.advancedDiagnosticsGroup,
            children: [
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: Text(l10n.settingsLogLevelTitle),
                subtitle: Text(l10n.settingsLogLevelSubtitle),
                trailing: Text(
                  _levelLabel(l10n, config.logLevel),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () => _showLogLevelSheet(context, ref, config.logLevel),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.article_outlined),
                title: Text(l10n.advancedViewLogsTitle),
                subtitle: Text(l10n.advancedViewLogsSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/logs'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
