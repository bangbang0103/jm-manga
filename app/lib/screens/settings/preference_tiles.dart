import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/config_provider.dart';
import '../../widgets/pill_selector.dart';

class ThemeModeTile extends ConsumerWidget {
  final ThemeMode value;

  const ThemeModeTile({super.key, required this.value});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.themeTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            PillSelector<ThemeMode>(
              values: const [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
              selected: value,
              labelFor: (mode) => switch (mode) {
                ThemeMode.system => l10n.themeSystem,
                ThemeMode.light => l10n.themeLight,
                ThemeMode.dark => l10n.themeDark,
              },
              onSelected: (mode) =>
                  ref.read(configProvider.notifier).setThemeMode(mode),
            ),
          ],
        ),
      ),
    );
  }
}

class LanguageTile extends ConsumerWidget {
  final Locale value;

  const LanguageTile({super.key, required this.value});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final entries = {
      const Locale('en'): l10n.languageEnglish,
      const Locale('zh'): l10n.languageChinese,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.languageTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            PillSelector<Locale>(
              values: entries.keys.toList(),
              selected: value,
              labelFor: (locale) => entries[locale]!,
              onSelected: (locale) {
                ref.read(configProvider.notifier).setLocale(locale);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PreloadTile extends ConsumerStatefulWidget {
  final int value;

  const PreloadTile({super.key, required this.value});

  @override
  ConsumerState<PreloadTile> createState() => _PreloadTileState();
}

class _PreloadTileState extends ConsumerState<PreloadTile> {
  Timer? _debounce;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.preloadTitle, style: theme.textTheme.titleSmall),
                Text(
                  widget.value.toString(),
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            Slider(
              value: widget.value.toDouble(),
              min: 0,
              max: 20,
              divisions: 20,
              label: widget.value.toString(),
              onChanged: (v) {
                final count = v.round();
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  ref.read(configProvider.notifier).setPreloadCount(count);
                });
              },
            ),
            Text(
              l10n.preloadSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

class GridDensityTile extends ConsumerWidget {
  final GridDensity value;

  const GridDensityTile({super.key, required this.value});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    String labelFor(GridDensity density) => switch (density) {
      GridDensity.compact => l10n.gridDensityCompact,
      GridDensity.standard => l10n.gridDensityStandard,
      GridDensity.loose => l10n.gridDensityLoose,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.gridDensityTitle, style: theme.textTheme.titleSmall),
                Text(labelFor(value), style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.gridDensitySubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            PillSelector<GridDensity>(
              values: GridDensity.values,
              selected: value,
              labelFor: labelFor,
              onSelected: (density) {
                ref.read(configProvider.notifier).setGridDensity(density);
              },
            ),
          ],
        ),
      ),
    );
  }
}
