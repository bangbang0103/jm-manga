import 'package:flutter/material.dart';
import 'package:jm_manga/l10n/app_localizations.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final sections = [
      (
        Icons.wifi_tethering,
        l10n.helpServerTitle,
        l10n.helpServerBody,
      ),
      (
        Icons.explore_outlined,
        l10n.helpBrowseTitle,
        l10n.helpBrowseBody,
      ),
      (
        Icons.favorite_outline,
        l10n.helpFavoriteTitle,
        l10n.helpFavoriteBody,
      ),
      (
        Icons.menu_book_outlined,
        l10n.helpReadTitle,
        l10n.helpReadBody,
      ),
      (
        Icons.account_circle_outlined,
        l10n.helpAccountTitle,
        l10n.helpAccountBody,
      ),
      (
        Icons.bug_report_outlined,
        l10n.helpLogTitle,
        l10n.helpLogBody,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _HeroSection(theme: theme, l10n: l10n),
            const SizedBox(height: 24),
            ...sections.map((section) {
              final (icon, title, body) = section;
              return _FeatureCard(
                icon: icon,
                title: title,
                body: body,
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final ThemeData theme;
  final AppLocalizations l10n;

  const _HeroSection({required this.theme, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/app_icon.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'JM Manga',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.helpIntro,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.primary;
    final iconBg = theme.colorScheme.primaryContainer.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
