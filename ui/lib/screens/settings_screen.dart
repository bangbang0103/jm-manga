import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/jm_account.dart';
import '../models/server.dart';
import '../providers/account_provider.dart';
import '../providers/album_providers.dart';
import '../providers/app_sync_provider.dart';
import '../providers/config_provider.dart';
import '../providers/device_provider.dart';
import '../providers/repository_provider.dart';
import '../providers/server_provider.dart';
import '../utils/app_logger.dart';
import '../utils/top_toast.dart';
import '../widgets/pill_selector.dart';

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

String _formatDuration(AppLocalizations l10n, int seconds) {
  if (seconds < 60) return '$seconds s';
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '$minutes m';
  final hours = minutes ~/ 60;
  if (hours < 24) {
    final m = minutes % 60;
    return '$hours h ${m.toString().padLeft(2, '0')} m';
  }
  final days = hours ~/ 24;
  final h = hours % 24;
  return '$days d $h h';
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    await ref.read(serverProvider.notifier).select(null);
    await ref.read(currentAccountIdProvider.notifier).select(null);
    if (context.mounted) context.go('/server');
  }

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

      final lastSync = ref.read(lastLoginRefreshSyncProvider);
      final now = DateTime.now();
      if (lastSync == null || now.difference(lastSync).inMinutes >= 1) {
        ref.read(lastLoginRefreshSyncProvider.notifier).state = now;
        unawaited(
          ref.read(favoritesProvider.notifier).sync().catchError((_) => false),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      TopToast.show(
        context,
        l10n.loginRefreshFailed(e.toString()),
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

  Future<void> _editAccount(
    BuildContext context,
    WidgetRef ref,
    JmAccount account,
  ) async {
    final result = await showDialog<_NewAccount>(
      context: context,
      builder: (_) => _AddAccountDialog(
        initialUsername: account.username,
        initialPassword: account.password,
        isEdit: true,
      ),
    );
    if (result == null) return;

    final password = result.password;
    if (password == account.password) return;

    final updated = account.copyWith(password: password);
    await ref.read(accountListProvider.notifier).updateAccount(updated);

    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    TopToast.show(context, l10n.loginRefreshed, type: TopToastType.success);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final server = ref.watch(serverProvider);
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
            _SectionTitle(title: l10n.sectionService),
            _ServiceCard(server: server),
            const SizedBox(height: 32),
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
                trailing: currentId == null
                    ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                    : null,
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
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          account.displayName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ],
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
                      if (!account.isAnonymous)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: l10n.actionEdit,
                          onPressed: () => _editAccount(context, ref, account),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
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
            if (!kIsWeb)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _disconnect(context, ref),
                  child: Text(l10n.disconnectService),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
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

class _ServiceCard extends StatelessWidget {
  final MangaServer? server;

  const _ServiceCard({this.server});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final online = server?.online == true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server?.name ?? l10n.statusUnknown,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (server?.version != null)
                            _Badge(text: 'v${server?.version}'),
                          const SizedBox(width: 8),
                          _Badge(
                            text: online
                                ? l10n.statusOnline
                                : (server != null
                                      ? l10n.statusOffline
                                      : l10n.statusUnknown),
                            color: online
                                ? theme.colorScheme.tertiaryContainer
                                : theme.colorScheme.surfaceContainerHighest,
                            foregroundColor: online
                                ? theme.colorScheme.onTertiaryContainer
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.link,
              text: server?.baseUrl ?? l10n.statusUnknown,
            ),
            const Divider(height: 24),
            _CacheInfoRows(),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? foregroundColor;

  const _Badge({required this.text, this.color, this.foregroundColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foregroundColor ?? theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AboutCard extends ConsumerWidget {
  final String? deviceId;

  const _AboutCard({this.deviceId});

  static const _gitHubUrl = 'https://github.com/QPH-Coding/jm-manga';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final id = deviceId;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.aboutVersion),
            trailing: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version ?? '...';
                return Text(
                  'v$version',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
          if (id != null && id.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.perm_device_info),
              title: Text(l10n.deviceIdLabel),
              subtitle: Text(
                id,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                tooltip: l10n.copiedToClipboard,
                onPressed: () => _copyDeviceId(context, id),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.code),
            title: Text(l10n.aboutGitHub),
            subtitle: Text(
              _gitHubUrl,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
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
            onTap: () => context.push('/help'),
          ),
          if (!kIsWeb)
            ListTile(
              leading: const Icon(Icons.article_outlined),
              title: Text(l10n.aboutViewLogs),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/logs'),
            ),
        ],
      ),
    );
  }
}

class _CacheInfoRows extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CacheInfoRows> createState() => _CacheInfoRowsState();
}

class _CacheStats {
  final int serverCoverCache;
  final int serverImageCache;
  final int databaseUsage;
  final int uptimeSeconds;

  const _CacheStats({
    required this.serverCoverCache,
    required this.serverImageCache,
    required this.databaseUsage,
    required this.uptimeSeconds,
  });
}

class _CacheInfoRowsState extends ConsumerState<_CacheInfoRows> {
  late Future<_CacheStats> _sizesFuture;

  @override
  void initState() {
    super.initState();
    _sizesFuture = _loadSizes();
  }

  Future<_CacheStats> _loadSizes() async {
    try {
      final repo = ref.read(apiRepositoryProvider);
      final serverSizes = await repo.getServerCacheSizes();
      final health = await repo.checkHealth();
      final uptime = (health['uptime_seconds'] as num?)?.toInt() ?? 0;
      return _CacheStats(
        serverCoverCache: serverSizes['covers'] ?? 0,
        serverImageCache: serverSizes['images'] ?? 0,
        databaseUsage: serverSizes['database'] ?? 0,
        uptimeSeconds: uptime,
      );
    } catch (_) {
      return const _CacheStats(
        serverCoverCache: 0,
        serverImageCache: 0,
        databaseUsage: 0,
        uptimeSeconds: 0,
      );
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _sizesFuture = _loadSizes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<_CacheStats>(
      future: _sizesFuture,
      builder: (context, snapshot) {
        final stats =
            snapshot.data ??
            const _CacheStats(
              serverCoverCache: 0,
              serverImageCache: 0,
              databaseUsage: 0,
              uptimeSeconds: 0,
            );
        final ready =
            snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(
              icon: Icons.timer_outlined,
              text:
                  '${l10n.uptimeLabel}: ${ready ? _formatDuration(l10n, stats.uptimeSeconds) : l10n.calculatingLabel}',
            ),
            _InfoRow(
              icon: Icons.image_outlined,
              text:
                  '${l10n.coverCacheLabel}: ${ready ? _formatBytes(stats.serverCoverCache) : l10n.calculatingLabel}',
            ),
            _InfoRow(
              icon: Icons.photo_library_outlined,
              text:
                  '${l10n.mangaImageCacheLabel}: ${ready ? _formatBytes(stats.serverImageCache) : l10n.calculatingLabel}',
            ),
            _InfoRow(
              icon: Icons.storage_outlined,
              text:
                  '${l10n.dataUsageLabel}: ${ready ? _formatBytes(stats.databaseUsage) : l10n.calculatingLabel}',
            ),
            if (ready)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _refresh,
                  child: Text(l10n.refreshLabel),
                ),
              ),
          ],
        );
      },
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
    final entries = {const Locale('en'): 'English', const Locale('zh'): '中文'};
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
  final String? initialUsername;
  final String? initialPassword;
  final bool isEdit;
  final Future<void> Function(String username, String password)? onLogin;

  const _AddAccountDialog({
    this.initialUsername,
    this.initialPassword,
    this.isEdit = false,
    this.onLogin,
  });

  @override
  State<_AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<_AddAccountDialog> {
  late final _usernameController = TextEditingController(
    text: widget.initialUsername ?? '',
  );
  late final _passwordController = TextEditingController(
    text: widget.initialPassword ?? '',
  );
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
    final actionLabel = isLoginMode
        ? l10n.actionLogin
        : (widget.isEdit ? l10n.actionEdit : l10n.actionAdd);
    final loadingLabel = isLoginMode ? l10n.actionLoginLoading : null;

    return AlertDialog(
      title: Text(
        widget.isEdit
            ? l10n.dialogEditAccountTitle
            : l10n.dialogAddAccountTitle,
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
            enabled: !_loading && !widget.isEdit,
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
