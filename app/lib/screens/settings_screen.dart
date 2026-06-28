import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_update_info.dart';
import '../models/jm_account.dart';
import '../providers/account_provider.dart';
import '../providers/app_update_provider.dart';
import '../providers/config_provider.dart';
import '../providers/device_provider.dart';
import '../providers/repository_provider.dart';
import '../utils/app_logger.dart';
import '../utils/error_mapper.dart';
import '../utils/top_toast.dart';
import '../widgets/pill_selector.dart';

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
    final result = await showDialog<_NewAccount>(
      context: context,
      builder: (_) => _AddAccountDialog(
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
            _ThemeModeTile(value: config.themeMode),
            _LanguageTile(value: config.locale),
            const SizedBox(height: 32),
            _SectionTitle(title: l10n.sectionReader),
            _PreloadTile(value: config.preloadCount),
            const SizedBox(height: 16),
            _GridColumnsTile(value: config.gridColumns),
            const SizedBox(height: 32),
            _SectionTitle(title: l10n.aboutTitle),
            _AboutCard(deviceId: ref.watch(deviceIdProvider)),
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

class _AboutCard extends ConsumerWidget {
  final String? deviceId;

  const _AboutCard({this.deviceId});

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
        builder: (context) => _UpdateDetailScreen(info: info),
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
                        decoration: const BoxDecoration(
                          color: Colors.red,
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

class _UpdateDetailScreen extends StatelessWidget {
  final AppUpdateInfo info;

  const _UpdateDetailScreen({required this.info});

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

class _ThemeModeTile extends ConsumerWidget {
  final ThemeMode value;

  const _ThemeModeTile({required this.value});

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

class _LanguageTile extends ConsumerWidget {
  final Locale value;

  const _LanguageTile({required this.value});

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

class _PreloadTile extends ConsumerStatefulWidget {
  final int value;

  const _PreloadTile({required this.value});

  @override
  ConsumerState<_PreloadTile> createState() => _PreloadTileState();
}

class _PreloadTileState extends ConsumerState<_PreloadTile> {
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

class _GridColumnsTile extends ConsumerWidget {
  final int value;

  const _GridColumnsTile({required this.value});

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.gridColumnsTitle, style: theme.textTheme.titleSmall),
                Text('$value', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.gridColumnsSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            PillSelector<int>(
              values: const [2, 3, 4],
              selected: value,
              labelFor: (v) => '$v',
              onSelected: (v) {
                ref.read(configProvider.notifier).setGridColumns(v);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NewAccount {
  final String username;
  final String password;

  _NewAccount({required this.username, required this.password});
}

class _AddAccountDialog extends StatefulWidget {
  final Future<void> Function(String username, String password)? onLogin;

  const _AddAccountDialog({this.onLogin});

  @override
  State<_AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<_AddAccountDialog> {
  late final _usernameController = TextEditingController();
  late final _passwordController = TextEditingController();
  bool _loading = false;
  String? _usernameError;
  String? _passwordError;
  String? _loginError;

  String _mapLoginError(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context)!;
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 401) return l10n.loginErrorUnauthorized;
      if (status != null) return l10n.loginErrorServer;
      return l10n.loginErrorNetwork;
    }
    return l10n.loginErrorServer;
  }

  Future<void> _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _usernameError = username.isEmpty ? l10n.fieldUsernameRequired : null;
      _passwordError = password.isEmpty ? l10n.fieldPasswordRequired : null;
      _loginError = null;
    });

    if (username.isEmpty || password.isEmpty) return;

    if (widget.onLogin != null) {
      setState(() => _loading = true);
      try {
        await widget.onLogin!(username, password);
        if (mounted) {
          Navigator.of(
            context,
          ).pop(_NewAccount(username: username, password: password));
        }
      } catch (e, st) {
        globalLogger.e('JM login failed', error: e, stackTrace: st);
        if (mounted) {
          setState(() {
            _loading = false;
            _loginError = _mapLoginError(context, e);
          });
        }
      }
    } else {
      Navigator.of(
        context,
      ).pop(_NewAccount(username: username, password: password));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLoginMode = widget.onLogin != null;
    final actionLabel = isLoginMode ? l10n.actionLogin : l10n.actionAdd;
    final loadingLabel = isLoginMode ? l10n.actionLoginLoading : null;

    return AlertDialog(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(l10n.dialogAddAccountTitle),
          ),
          if (isLoginMode) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: l10n.loginMergeFavoritesHint,
              child: Icon(
                Icons.help_outline,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: l10n.fieldUsername,
              errorText: _usernameError,
            ),
            enabled: !_loading,
            onChanged: (_) {
              if (_usernameError != null) {
                setState(() => _usernameError = null);
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: l10n.fieldPassword,
              errorText: _passwordError,
            ),
            obscureText: true,
            enabled: !_loading,
            onChanged: (_) {
              if (_passwordError != null) {
                setState(() => _passwordError = null);
              }
            },
          ),
          if (_loginError != null) ...[
            const SizedBox(height: 12),
            Text(
              _loginError!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _loading ? null : _handleSubmit,
          child: _loading && loadingLabel != null
              ? Text(loadingLabel)
              : Text(actionLabel),
        ),
      ],
    );
  }
}
