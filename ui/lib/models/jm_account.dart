import 'package:uuid/uuid.dart';

class JmAccount {
  final String id;
  final String? username;
  final String? password;
  final bool isAnonymous;

  JmAccount({
    String? id,
    this.username,
    this.password,
    this.isAnonymous = false,
  }) : id = id ?? const Uuid().v4();

  String get displayName => isAnonymous ? 'Anonymous' : (username ?? 'Unknown');

  JmAccount copyWith({String? username, String? password, bool? isAnonymous}) {
    return JmAccount(
      id: id,
      username: username ?? this.username,
      password: password ?? this.password,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }

  /// 用于持久化的 JSON，不包含密码等敏感字段。
  Map<String, dynamic> toPublicJson() => {
    'id': id,
    'username': username,
    'isAnonymous': isAnonymous,
  };

  factory JmAccount.fromJson(Map<String, dynamic> json) {
    return JmAccount(
      id: json['id'] as String?,
      username: json['username'] as String?,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
    );
  }
}
