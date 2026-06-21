import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

import '../utils/app_logger.dart';
import '../utils/top_toast.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  LogLevel? _filter;

  Color _levelColor(LogLevel level, ColorScheme scheme) {
    return switch (level) {
      LogLevel.verbose => scheme.outline,
      LogLevel.debug => scheme.primary,
      LogLevel.info => scheme.onSurface,
      LogLevel.warning => scheme.tertiary,
      LogLevel.error => scheme.error,
    };
  }

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final path = await globalLogger.exportToTempFile();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          subject: 'JM Manga logs',
        ),
      );
    } catch (e) {
      if (mounted) {
        TopToast.show(
          context,
          l10n.errorWithMessage(e.toString()),
          type: TopToastType.error,
        );
      }
    }
  }

  Future<void> _copyEntry(LogEntry entry) async {
    final buffer = StringBuffer()
      ..write('[${entry.formattedTime}] ')
      ..write('[${entry.level.label}] ')
      ..writeln(entry.message);
    if (entry.error != null) buffer.writeln(entry.error);
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      TopToast.show(context, AppLocalizations.of(context)!.copiedToClipboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: globalLogger,
      builder: (context, _) {
        final allEntries = globalLogger.entries;
    final entries = _filter == null
        ? allEntries
        : allEntries.where((e) => e.level.index >= _filter!.index).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.logsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: l10n.logsExport,
            onPressed: allEntries.isEmpty ? null : _export,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.logsClear,
            onPressed: allEntries.isEmpty ? null : () => globalLogger.clear(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: l10n.logsAllLevels,
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                  ...LogLevel.values.map((level) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _FilterChip(
                        label: level.label,
                        selected: _filter == level,
                        color: _levelColor(level, theme.colorScheme),
                        onSelected: (_) => setState(() => _filter = level),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      l10n.logsEmpty,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 24,
                    ),
                    itemCount: entries.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final color = _levelColor(entry.level, theme.colorScheme);
                      return InkWell(
                        onLongPress: () => _copyEntry(entry),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      entry.level.short,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    entry.formattedTime,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                entry.message,
                                style: theme.textTheme.bodyMedium,
                              ),
                              if (entry.error != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    entry.error.toString(),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = color ?? theme.colorScheme.onSurface;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        color: selected ? theme.colorScheme.onPrimary : foreground,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide.none,
      showCheckmark: false,
    );
  }
}
