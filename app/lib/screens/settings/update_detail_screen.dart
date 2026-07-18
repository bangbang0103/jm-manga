import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_update_info.dart';

class UpdateDetailScreen extends StatelessWidget {
  final AppUpdateInfo info;

  const UpdateDetailScreen({super.key, required this.info});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final notesEmpty = info.releaseNotes.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          l10n.newVersionTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () => _launchUrl(info.releaseUrl),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(l10n.updateNow),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${info.version} - ${l10n.releaseNotesLabel}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Divider(color: theme.colorScheme.outlineVariant, height: 1),
              const SizedBox(height: 16),
              if (notesEmpty)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      Icon(
                        Icons.notes_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.noReleaseNotes,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else
                MarkdownBody(
                  data: info.releaseNotes,
                  selectable: true,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
