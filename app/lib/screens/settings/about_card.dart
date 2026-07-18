import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_update_info.dart';
import '../../providers/app_update_provider.dart';
import '../../utils/error_mapper.dart';
import '../../utils/top_toast.dart';
import 'update_detail_screen.dart';

class AboutCard extends ConsumerWidget {
  final String? deviceId;

  const AboutCard({super.key, this.deviceId});

  static const _gitHubUrl = 'https://github.com/bangbang0103/jm-manga';
  static const _issuesUrl = '$_gitHubUrl/issues/new';

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _copyDeviceId(BuildContext context, String id) async {
    await Clipboard.setData(ClipboardData(text: id));
    if (context.mounted) {
      TopToast.show(
        context,
        AppLocalizations.of(context)!.deviceIdCopied,
        type: TopToastType.success,
      );
    }
  }

  String _shortenDeviceId(String id) {
    if (id.length <= 16) return id;
    return '${id.substring(0, 6)}...${id.substring(id.length - 6)}';
  }

  Future<void> _openUpdateDetail(BuildContext context, AppUpdateInfo info) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => UpdateDetailScreen(info: info),
      ),
    );
  }

  Future<void> _handleVersionTap(
    BuildContext context,
    WidgetRef ref,
    AppUpdateState state,
  ) async {
    if (state.hasUpdate) {
      await _openUpdateDetail(context, state.latestInfo!);
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(appUpdateProvider.notifier);
    await notifier.checkForUpdates(silent: false);

    final updated = ref.read(appUpdateProvider);
    if (!context.mounted) return;

    if (updated.error != null) {
      TopToast.show(
        context,
        mapErrorToUserMessage(updated.error!, l10n),
        type: TopToastType.error,
      );
      return;
    }

    if (!updated.hasUpdate) {
      TopToast.show(
        context,
        l10n.alreadyUpToDate,
        type: TopToastType.success,
      );
    } else {
      await _openUpdateDetail(context, updated.latestInfo!);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final id = deviceId;
    final updateState = ref.watch(appUpdateProvider);

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.aboutVersion),
            trailing: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (updateState.isChecking) {
                  return const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                final version = snapshot.data?.version ?? '...';
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (updateState.hasUpdate) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      'v$version',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              },
            ),
            onTap: () => _handleVersionTap(context, ref, updateState),
          ),
          if (id != null && id.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.perm_device_info),
              title: Text(l10n.deviceIdLabel),
              trailing: SizedBox(
                width: 140,
                child: Text(
                  _shortenDeviceId(id),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              onTap: () => _copyDeviceId(context, id),
            ),
          ListTile(
            leading: const Icon(Icons.code),
            title: Text(l10n.aboutGitHub),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _openUrl(_gitHubUrl),
          ),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: Text(l10n.aboutFeedback),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _openUrl(_issuesUrl),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(l10n.aboutHelp),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/faq'),
          ),
          if (!kIsWeb) ...[
            ListTile(
              leading: const Icon(Icons.storage_outlined),
              title: Text(l10n.aboutCache),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/cache'),
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: Text(l10n.advancedSettingsTitle),
              subtitle: Text(l10n.advancedSettingsSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/advanced'),
            ),
          ],
        ],
      ),
    );
  }
}
