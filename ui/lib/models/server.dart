import 'package:uuid/uuid.dart';

class MangaServer {
  final String id;
  final String name;
  final String scheme;
  final String host;
  final int port;
  final String? token;
  final String? version;
  final int? uptimeSeconds;
  final bool online;
  final DateTime? lastSeen;

  MangaServer({
    String? id,
    required this.name,
    this.scheme = 'http',
    required this.host,
    required this.port,
    this.token,
    this.version,
    this.uptimeSeconds,
    this.online = false,
    this.lastSeen,
  }) : id = id ?? const Uuid().v4();

  String get baseUrl {
    final defaultPort =
        (scheme == 'https' && port == 443) || (scheme == 'http' && port == 80);
    return defaultPort ? '$scheme://$host' : '$scheme://$host:$port';
  }

  MangaServer copyWith({
    String? name,
    String? scheme,
    String? host,
    int? port,
    String? token,
    String? version,
    int? uptimeSeconds,
    bool? online,
    DateTime? lastSeen,
  }) {
    return MangaServer(
      id: id,
      name: name ?? this.name,
      scheme: scheme ?? this.scheme,
      host: host ?? this.host,
      port: port ?? this.port,
      token: token ?? this.token,
      version: version ?? this.version,
      uptimeSeconds: uptimeSeconds ?? this.uptimeSeconds,
      online: online ?? this.online,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  /// 用于持久化的 JSON，不包含 token 等敏感字段。
  Map<String, dynamic> toPublicJson() => {
    'id': id,
    'name': name,
    'scheme': scheme,
    'host': host,
    'port': port,
    'version': version,
    'uptimeSeconds': uptimeSeconds,
    'online': online,
    'lastSeen': lastSeen?.toIso8601String(),
  };

  factory MangaServer.fromJson(Map<String, dynamic> json) {
    return MangaServer(
      id: json['id'] as String?,
      name: json['name'] as String,
      scheme: json['scheme'] as String? ?? 'http',
      host: json['host'] as String,
      port: json['port'] as int,
      version: json['version'] as String?,
      uptimeSeconds: json['uptimeSeconds'] as int?,
      online: json['online'] as bool? ?? false,
      lastSeen: json['lastSeen'] == null
          ? null
          : DateTime.tryParse(json['lastSeen'] as String),
    );
  }
}
