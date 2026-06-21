import 'dart:async';
import 'dart:convert';

import 'package:flutter_multicast_lock/flutter_multicast_lock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/server.dart';
import '../utils/secure_storage.dart';

final serverProvider = StateNotifierProvider<ServerNotifier, MangaServer?>((
  ref,
) {
  return ServerNotifier();
});

final serverListProvider =
    StateNotifierProvider<ServerListNotifier, List<MangaServer>>((ref) {
      return ServerListNotifier();
    });

class ServerNotifier extends StateNotifier<MangaServer?> {
  static const _key = 'selected_server';

  ServerNotifier() : super(null) {
    load();
  }

  static String _tokenKey(String id) => 'server_token_$id';

  Future<MangaServer?> _loadToken(MangaServer server) async {
    final token = await SecureStorage.read(_tokenKey(server.id));
    if (token == null || token.isEmpty) return server;
    return server.copyWith(token: token);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json != null) {
      try {
        final server = MangaServer.fromJson(
          jsonDecode(json) as Map<String, dynamic>,
        );
        state = await _loadToken(server);
      } catch (_) {
        state = null;
      }
    }
  }

  Future<void> select(MangaServer? server) async {
    state = server;
    final prefs = await SharedPreferences.getInstance();
    if (server == null) {
      await prefs.remove(_key);
    } else {
      await SecureStorage.write(_tokenKey(server.id), server.token);
      await prefs.setString(_key, jsonEncode(server.toPublicJson()));
    }
  }
}

class ServerListNotifier extends StateNotifier<List<MangaServer>> {
  static const _key = 'saved_servers';

  ServerListNotifier() : super([]) {
    load();
  }

  static String _tokenKey(String id) => 'server_token_$id';

  Future<MangaServer> _loadToken(MangaServer server) async {
    final token = await SecureStorage.read(_tokenKey(server.id));
    if (token == null || token.isEmpty) return server;
    return server.copyWith(token: token);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json != null) {
      try {
        final list = jsonDecode(json) as List<dynamic>;
        final servers = <MangaServer>[];
        for (final item in list) {
          final server = MangaServer.fromJson(item as Map<String, dynamic>);
          servers.add(await _loadToken(server));
        }
        state = servers;
      } catch (_) {
        state = [];
      }
    }
  }

  Future<void> save(List<MangaServer> servers) async {
    state = servers;
    final prefs = await SharedPreferences.getInstance();
    // 敏感 token 单独加密存储，JSON 中只保留非敏感字段
    for (final server in servers) {
      await SecureStorage.write(_tokenKey(server.id), server.token);
    }
    await prefs.setString(
      _key,
      jsonEncode(servers.map((s) => s.toPublicJson()).toList()),
    );
  }

  Future<void> addOrUpdate(MangaServer server) async {
    final existing = state.indexWhere((s) => s.id == server.id);
    final updated = List<MangaServer>.from(state);
    if (existing >= 0) {
      updated[existing] = server;
    } else {
      updated.add(server);
    }
    await save(updated);
  }

  Future<void> remove(String id) async {
    final updated = state.where((s) => s.id != id).toList();
    await SecureStorage.delete(_tokenKey(id));
    await save(updated);
  }
}

class MdnsDiscoveryService {
  final _client = MDnsClient();
  final _lock = FlutterMulticastLock();
  final Set<String> _found = {};
  final _controller = StreamController<MangaServer>.broadcast();

  Stream<MangaServer> get stream => _controller.stream;

  static const _ptrTimeout = Duration(seconds: 2);
  static const _srvTimeout = Duration(seconds: 3);
  static const _aTimeout = Duration(seconds: 3);

  Future<void> start() async {
    try {
      await _lock.acquireMulticastLock();
    } catch (_) {
      // 非 Android 平台或其他原因获取锁失败时继续扫描。
    }
    await _client.start();
    await for (final ptr in _client.lookup<PtrResourceRecord>(
      ResourceRecordQuery.serverPointer('_http._tcp'),
      timeout: _ptrTimeout,
    )) {
      unawaited(_resolveService(ptr.domainName));
    }
  }

  Future<void> _resolveService(String serviceName) async {
    await for (final srv in _client.lookup<SrvResourceRecord>(
      ResourceRecordQuery.service(serviceName),
      timeout: _srvTimeout,
    )) {
      await for (final ip in _client.lookup<IPAddressResourceRecord>(
        ResourceRecordQuery.addressIPv4(srv.target),
        timeout: _aTimeout,
      )) {
        final host = ip.address.address;
        final port = srv.port;
        final id = '$host:$port';
        if (_found.add(id)) {
          final rawName = srv.name.replaceAll('._http._tcp.local', '');
          if (rawName.toLowerCase().startsWith('jmmanga-server ')) {
            final name = rawName.substring('jmmanga-server '.length);
            _controller.add(MangaServer(name: name, host: host, port: port));
          }
        }
      }
    }
  }

  Future<void> stop() async {
    _client.stop();
    try {
      await _lock.releaseMulticastLock();
    } catch (_) {
      // 忽略平台不支持导致的释放失败。
    }
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}
