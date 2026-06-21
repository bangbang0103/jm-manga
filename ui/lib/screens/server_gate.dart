import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/api_client.dart';
import '../data/api_repository.dart';
import '../models/server.dart';
import '../providers/account_provider.dart';
import '../providers/config_provider.dart';
import '../providers/server_provider.dart';
import '../utils/top_toast.dart';
import '../widgets/loading_indicator.dart';

class ServerGate extends ConsumerStatefulWidget {
  const ServerGate({super.key});

  @override
  ConsumerState<ServerGate> createState() => _ServerGateState();
}

class _ServerGateState extends ConsumerState<ServerGate> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await ref.read(serverProvider.notifier).load();
    await ref.read(configProvider.notifier).load();
    // 让 account provider 的异步初始化有机会完成
    await Future.delayed(Duration.zero);
    final currentId = ref.read(currentAccountIdProvider);
    final accounts = ref.read(accountListProvider);
    if (currentId == null && accounts.isNotEmpty) {
      await ref
          .read(currentAccountIdProvider.notifier)
          .select(accounts.first.id);
    }
    if (kIsWeb) {
      await _initWeb();
      return;
    }
    final server = ref.read(serverProvider);
    if (server == null) {
      if (mounted) context.replace('/server');
      return;
    }

    try {
      final tempClient = ApiClient(
        baseUrl: server.baseUrl,
        apiToken: server.token,
      );
      final repo = ApiRepository(client: tempClient);
      final health = await repo.validateConnection().timeout(
        const Duration(seconds: 10),
      );
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
      if (mounted) context.replace('/');
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        TopToast.show(
          context,
          l10n.serverGateReconnectFailed,
          type: TopToastType.info,
        );
        context.replace('/server');
      }
    }
  }

  Future<void> _initWeb() async {
    final origin = Uri.base.origin;
    final originUri = Uri.parse(origin);
    final port = originUri.hasPort
        ? originUri.port
        : (originUri.scheme == 'https' ? 443 : 80);
    final config = ref.read(configProvider);
    final server = MangaServer(
      name: originUri.host,
      scheme: originUri.scheme,
      host: originUri.host,
      port: port,
      token: config.apiToken,
      online: true,
      lastSeen: DateTime.now(),
    );

    try {
      await _connectWebServer(server);
      if (mounted) context.replace('/');
    } catch (_) {
      if (!mounted) return;
      final connected = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _WebTokenDialog(
          server: server,
          onConnect: (token) => _connectWebServer(
            server.copyWith(token: token.isEmpty ? null : token),
          ),
        ),
      );
      if (connected == true && mounted) context.replace('/');
    }
  }

  Future<void> _connectWebServer(MangaServer server) async {
    final tempClient = ApiClient(
      baseUrl: server.baseUrl,
      apiToken: server.token,
    );
    final repo = ApiRepository(client: tempClient);
    final health = await repo.validateConnection().timeout(
      const Duration(seconds: 10),
    );
    final updated = server.copyWith(
      version: health['version'] as String?,
      uptimeSeconds: health['uptime_seconds'] as int?,
      online: true,
      lastSeen: DateTime.now(),
    );
    await ref.read(serverProvider.notifier).select(updated);
    await ref
        .read(configProvider.notifier)
        .setConnection(updated.baseUrl, updated.token);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: AppLoadingIndicator(size: 32)));
  }
}

class _WebTokenDialog extends StatefulWidget {
  final MangaServer server;
  final Future<void> Function(String token) onConnect;

  const _WebTokenDialog({required this.server, required this.onConnect});

  @override
  State<_WebTokenDialog> createState() => _WebTokenDialogState();
}

class _WebTokenDialogState extends State<_WebTokenDialog> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _handleConnect() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onConnect(_controller.text.trim());
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
          Text(widget.server.baseUrl),
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
