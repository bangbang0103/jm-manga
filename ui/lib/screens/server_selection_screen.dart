import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/api_client.dart';
import '../data/api_repository.dart';
import '../models/server.dart';
import '../providers/config_provider.dart';
import '../providers/server_provider.dart';
import '../utils/top_toast.dart';
import '../widgets/pill_selector.dart';

class ServerSelectionScreen extends ConsumerStatefulWidget {
  const ServerSelectionScreen({super.key});

  @override
  ConsumerState<ServerSelectionScreen> createState() =>
      _ServerSelectionScreenState();
}

class _ServerSelectionScreenState extends ConsumerState<ServerSelectionScreen> {
  bool _scanning = false;
  bool _refreshing = false;
  List<MangaServer> _discovered = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_refreshServerStatus);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final savedServers = ref.watch(serverListProvider);

    final locale = ref.watch(configProvider).locale;
    final locales = {const Locale('en'): 'English', const Locale('zh'): '中文'};
    final mergedServers = _mergedServers(savedServers);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const SizedBox.shrink(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PillSelector<Locale>(
              values: locales.keys.toList(),
              selected: locale,
              labelFor: (l) => locales[l]!,
              onSelected: (l) {
                ref.read(configProvider.notifier).setLocale(l);
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/app_icon.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('JM Manga', style: theme.textTheme.headlineLarge),
                    const SizedBox(height: 8),
                    Text(
                      l10n.serviceSubtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.add_circle,
                        label: l10n.actionManualAdd,
                        onTap: _showManualAddDialog,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.network_check,
                        label: l10n.actionScanLan,
                        loadingLabel: l10n.actionScanLanLoading,
                        outlined: true,
                        loading: _scanning,
                        onTap: _scanning ? null : _scanLan,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(top: 24)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.sectionYourServices,
                          style: theme.textTheme.titleLarge,
                        ),
                        if (_refreshing) ...[
                          const SizedBox(width: 10),
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: l10n.actionRefresh,
                      onPressed: _refreshing ? null : _refreshServerStatus,
                    ),
                  ],
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(top: 12)),
            if (mergedServers.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                sliver: SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.dns_outlined,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.serviceEmptyTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.serviceEmptyHint,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final server = mergedServers[index];
                    return _ServiceCard(
                      server: server,
                      onTap: () => _onServerTap(server),
                      onDelete: () => _deleteServer(server),
                    );
                  }, childCount: mergedServers.length),
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }

  List<MangaServer> _mergedServers(List<MangaServer> saved) {
    final byId = {for (final s in saved) s.id: s};
    for (final d in _discovered) {
      final existing = saved.cast<MangaServer?>().firstWhere(
        (s) => s?.host == d.host && s?.port == d.port,
        orElse: () => null,
      );
      if (existing == null) {
        byId[d.id] = d;
      }
    }
    return byId.values.toList();
  }

  Future<MangaServer> _probeServer(MangaServer server) async {
    try {
      final tempClient = ApiClient(
        baseUrl: server.baseUrl,
        apiToken: server.token,
      );
      final repo = ApiRepository(client: tempClient);
      final health = await repo.validateConnection();
      return server.copyWith(
        version: health['version'] as String?,
        uptimeSeconds: health['uptime_seconds'] as int?,
        online: true,
        lastSeen: DateTime.now(),
      );
    } catch (_) {
      return server.copyWith(online: false);
    }
  }

  Future<void> _refreshServerStatus() async {
    while (_refreshing && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted) return;
    setState(() => _refreshing = true);
    final saved = ref.read(serverListProvider);
    final merged = _mergedServers(saved);
    final updatedSaved = <MangaServer>[];
    final updatedDiscovered = List<MangaServer>.from(_discovered);
    for (final server in merged) {
      final updated = await _probeServer(server);
      final savedIndex = saved.indexWhere((s) => s.id == server.id);
      if (savedIndex >= 0) {
        updatedSaved.add(updated);
      } else {
        final idx = updatedDiscovered.indexWhere(
          (s) => s.host == server.host && s.port == server.port,
        );
        if (idx >= 0) updatedDiscovered[idx] = updated;
      }
    }
    if (updatedSaved.isNotEmpty) {
      await ref.read(serverListProvider.notifier).save(updatedSaved);
    }
    final selected = ref.read(serverProvider);
    if (selected != null) {
      final newSelected = updatedSaved.cast<MangaServer?>().firstWhere(
        (s) => s?.id == selected.id,
        orElse: () => null,
      );
      if (newSelected != null) {
        await ref.read(serverProvider.notifier).select(newSelected);
      }
    }
    if (mounted) {
      setState(() {
        _discovered = updatedDiscovered;
        _refreshing = false;
      });
    }
  }

  Future<void> _scanLan() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _scanning = true;
      _discovered = [];
    });
    final service = MdnsDiscoveryService();
    final probing = <String>{};
    final subscription = service.stream.listen((server) {
      final key = '${server.host}:${server.port}';
      if (_discovered.any(
            (s) => s.host == server.host && s.port == server.port,
          ) ||
          !probing.add(key)) {
        return;
      }
      unawaited(() async {
        final checked = await _probeServer(server);
        if (mounted) {
          setState(() => _discovered.add(checked));
        }
      }());
    });
    // 启动 mDNS 监听；等待 PTR 查询结束后再留一段时间给 SRV/A 解析。
    await service.start().catchError((_) {});
    await Future.delayed(const Duration(seconds: 5));
    await subscription.cancel();
    await service.stop();
    if (mounted) {
      setState(() => _scanning = false);
      if (_discovered.isEmpty && ref.read(serverListProvider).isEmpty) {
        TopToast.show(
          context,
          l10n.scanNoServicesFound,
          type: TopToastType.info,
        );
      }
    }
  }

  Future<void> _onServerTap(MangaServer server) async {
    final connected = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ConnectDialog(
        server: server,
        onConnect: (token) => _performConnect(
          server.copyWith(token: token.isEmpty ? null : token),
        ),
      ),
    );
    if (connected == true && mounted) {
      context.go('/');
    }
  }

  Future<void> _performConnect(MangaServer server) async {
    final tempClient = ApiClient(
      baseUrl: server.baseUrl,
      apiToken: server.token,
    );
    final repo = ApiRepository(client: tempClient);
    final health = await repo.validateConnection();
    final updated = server.copyWith(
      version: health['version'] as String?,
      uptimeSeconds: health['uptime_seconds'] as int?,
      online: true,
      lastSeen: DateTime.now(),
    );
    await ref.read(serverListProvider.notifier).addOrUpdate(updated);
    await ref.read(serverProvider.notifier).select(updated);
    await ref
        .read(configProvider.notifier)
        .setConnection(updated.baseUrl, updated.token);
  }

  Future<void> _connectWithToast(MangaServer server) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _performConnect(server);
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        TopToast.show(
          context,
          '${l10n.connectFailed(e.toString())}\n${l10n.connectFailedHint}',
          type: TopToastType.error,
        );
      }
    }
  }

  Future<void> _deleteServer(MangaServer server) async {
    setState(() {
      _discovered.removeWhere(
        (s) => s.host == server.host && s.port == server.port,
      );
    });
    await ref.read(serverListProvider.notifier).remove(server.id);
    final selected = ref.read(serverProvider);
    if (selected?.id == server.id ||
        (selected?.host == server.host && selected?.port == server.port)) {
      await ref.read(serverProvider.notifier).select(null);
    }
  }

  Future<void> _showManualAddDialog() async {
    final result = await showDialog<_ManualServer>(
      context: context,
      builder: (_) => const _ManualAddDialog(),
    );
    if (result == null) return;
    final server = MangaServer(
      name: result.name,
      host: result.host,
      port: result.port,
      token: result.token.isEmpty ? null : result.token,
    );
    await _connectWithToast(server);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? loadingLabel;
  final bool outlined;
  final bool loading;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.loadingLabel,
    this.outlined = false,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = outlined
        ? theme.colorScheme.primary
        : theme.colorScheme.onPrimary;
    final isDisabled = onTap == null || loading;
    return Material(
      color: outlined
          ? theme.colorScheme.surfaceContainer
          : theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: loading && loadingLabel == null
                    ? CircularProgressIndicator(strokeWidth: 2, color: foreground)
                    : Icon(icon, color: foreground),
              ),
              const SizedBox(height: 8),
              Text(
                loading && loadingLabel != null ? loadingLabel! : label,
                style: theme.textTheme.labelLarge?.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final MangaServer server;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ServiceCard({
    required this.server,
    required this.onTap,
    required this.onDelete,
  });

  static String _formatUptime(int? seconds) {
    if (seconds == null || seconds <= 0) return '';
    final d = Duration(seconds: seconds);
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}m');
    if (parts.isEmpty) parts.add('${seconds}s');
    return parts.join(' ');
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.dialogDeleteServerTitle),
          content: Text(l10n.dialogDeleteServerContent(server.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.actionDelete),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: server.online
                                ? theme.colorScheme.tertiary
                                : theme.colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          server.online
                              ? l10n.statusOnline
                              : l10n.statusOffline,
                          style: theme.textTheme.bodySmall,
                        ),
                        if (server.version != null) ...[
                          const SizedBox(width: 6),
                          Text('•', style: theme.textTheme.bodySmall),
                          const SizedBox(width: 6),
                          Text(
                            'v${server.version}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                        if (server.online && server.uptimeSeconds != null) ...[
                          const SizedBox(width: 6),
                          Text('•', style: theme.textTheme.bodySmall),
                          const SizedBox(width: 6),
                          Text(
                            _formatUptime(server.uptimeSeconds),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${server.host}:${server.port}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.actionDelete,
                onPressed: () => _confirmDelete(context),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectDialog extends StatefulWidget {
  final MangaServer server;
  final Future<void> Function(String token) onConnect;

  const _ConnectDialog({required this.server, required this.onConnect});

  @override
  State<_ConnectDialog> createState() => _ConnectDialogState();
}

class _ConnectDialogState extends State<_ConnectDialog> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _handleConnect() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onConnect(_controller.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.dialogConnectTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.server.host}:${widget.server.port}'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            enabled: !_loading,
            decoration: InputDecoration(
              labelText: l10n.fieldTokenOptional,
              hintText: l10n.tokenHint,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.connectFailedHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
          onPressed: _loading ? null : _handleConnect,
          child: _loading
              ? Text(l10n.actionConnectLoading)
              : Text(l10n.actionConnect),
        ),
      ],
    );
  }
}

class _ManualAddDialog extends StatefulWidget {
  const _ManualAddDialog();

  @override
  State<_ManualAddDialog> createState() => _ManualAddDialogState();
}

class _ManualAddDialogState extends State<_ManualAddDialog> {
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '8000');
  final _tokenController = TextEditingController();
  String? _hostError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.dialogManualTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.fieldNameOptional,
              hintText: l10n.nameHint,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hostController,
            decoration: InputDecoration(
              labelText: l10n.fieldHost,
              hintText: l10n.hostHint,
              errorText: _hostError,
            ),
            onChanged: (_) {
              if (_hostError != null) setState(() => _hostError = null);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _portController,
            decoration: InputDecoration(
              labelText: l10n.fieldPort,
              hintText: l10n.portHint,
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tokenController,
            decoration: InputDecoration(labelText: l10n.fieldTokenOptional),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final host = _hostController.text.trim();
            final port = int.tryParse(_portController.text.trim()) ?? 8000;
            final token = _tokenController.text.trim();
            if (host.isEmpty) {
              setState(() => _hostError = l10n.fieldHostRequired);
              return;
            }
            Navigator.of(context).pop(
              _ManualServer(
                name: name.isEmpty ? host : name,
                host: host,
                port: port,
                token: token,
              ),
            );
          },
          child: Text(l10n.actionConnect),
        ),
      ],
    );
  }
}

class _ManualServer {
  final String name;
  final String host;
  final int port;
  final String token;

  _ManualServer({
    required this.name,
    required this.host,
    required this.port,
    required this.token,
  });
}
