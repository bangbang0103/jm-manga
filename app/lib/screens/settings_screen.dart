import 'package:flutter/material.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/jm_account.dart';
import '../providers/account_provider.dart';
import '../providers/config_provider.dart';
import '../providers/device_provider.dart';
import '../providers/repository_provider.dart';
import '../utils/error_mapper.dart';
import '../utils/top_toast.dart';
import 'settings/about_card.dart';
import 'settings/add_account_dialog.dart';
import 'settings/preference_tiles.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _selectAccount(WidgetRef ref, String? id) async {
    await ref.read(currentAccountIdProvider.notifier).select(id);
  }

  Future<void> _removeAccount(
    BuildContext context,
    WidgetRef ref,
    JmAccount account,
  ) async {
    final current = ref.read(currentAccountIdProvider);
    if (current == account.id) {
      await ref.read(currentAccountIdProvider.notifier).select(null);
    }
    await ref.read(accountListProvider.notifier).removeAccount(account.id);
    ref.invalidate(apiRepositoryProvider);
  }

  Future<void> _refreshLogin(
    BuildContext context,
    WidgetRef ref,
    JmAccount account,
  ) async {
    if (account.isAnonymous ||
        account.username == null ||
        account.password == null) {
      return;
    }
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(apiRepositoryProvider);
    TopToast.show(context, l10n.loginRefreshing);
    try {
      await repo.loginToJm(account.username!, account.password!);
      if (!context.mounted) return;
      TopToast.show(context, l10n.loginRefreshed, type: TopToastType.success);

      final shouldGo = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.loginRefreshSyncTitle),
          content: Text(l10n.loginRefreshSyncBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.loginRefreshSyncLater),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.loginRefreshSyncGo),
            ),
          ],
        ),
      );
      if (shouldGo == true && context.mounted) {
        context.go('/?tab=library');
      }
    } catch (e) {
      if (!context.mounted) return;
      TopToast.show(
        context,
        mapErrorToUserMessage(e, l10n),
        type: TopToastType.error,
      );
    }
  }

  Future<void> _addAccount(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(apiRepositoryProvider);
    final result = await showDialog<NewAccount>(
      context: context,
      builder: (_) => AddAccountDialog(
        onLogin: (username, password) => repo.loginToJm(username, password),
      ),
    );
    if (result == null) return;

    final account = JmAccount(
      username: result.username,
      password: result.password,
    );
    await ref.read(accountListProvider.notifier).addAccount(account);
    await ref.read(currentAccountIdProvider.notifier).select(account.id);
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    TopToast.show(context, l10n.loginAccountAdded, type: TopToastType.success);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final accounts = ref.watch(accountListProvider);
    final currentId = ref.watch(currentAccountIdProvider);
    final config = ref.watch(configProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _AppHeader(),
            const SizedBox(height: 24),
            _SectionTitle(
              title: l10n.sectionAccounts,
              trailing: IconButton(
                icon: const Icon(Icons.add),
                tooltip: l10n.accountAddTooltip,
                onPressed: () => _addAccount(context, ref),
              ),
            ),
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  Icons.no_accounts,
                  color: currentId == null ? theme.colorScheme.primary : null,
                ),
                title: Text(l10n.accountAnonymous),
                selected: currentId == null,
                onTap: () => _selectAccount(ref, null),
              ),
            ),
            ...accounts.map((account) {
              final selected = account.id == currentId;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    account.isAnonymous ? Icons.no_accounts : Icons.person,
                    color: selected ? theme.colorScheme.primary : null,
                  ),
                  title: Text(
                    account.displayName,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected &&
                          !account.isAnonymous &&
                          account.password != null)
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: l10n.accountRefreshTooltip,
                          onPressed: () => _refreshLogin(context, ref, account),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: l10n.actionDelete,
                        onPressed: () => _removeAccount(context, ref, account),
                      ),
                    ],
                  ),
                  onTap: () => _selectAccount(ref, account.id),
                  selected: selected,
                ),
              );
            }),
            const SizedBox(height: 32),
            _SectionTitle(title: l10n.sectionAppearance),
            ThemeModeTile(value: config.themeMode),
            LanguageTile(value: config.locale),
            const SizedBox(height: 32),
            _SectionTitle(title: l10n.sectionReader),
            const SizedBox(height: 16),
            PreloadTile(value: config.preloadCount),
            const SizedBox(height: 16),
            GridColumnsTile(value: config.gridColumns),
            const SizedBox(height: 32),
            _SectionTitle(title: l10n.aboutTitle),
            AboutCard(deviceId: ref.watch(deviceIdProvider)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionTitle({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/app_icon.png',
              width: 88,
              height: 88,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'JM Manga',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
