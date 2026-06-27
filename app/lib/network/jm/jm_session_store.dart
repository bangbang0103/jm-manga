import 'dart:convert';

import '../../utils/secure_storage.dart';

class JmSessionStore {
  const JmSessionStore();

  static String _key(String username) => 'jm_session_cookies_$username';

  Future<Map<String, String>> readCookies(String username) async {
    final raw = await SecureStorage.read(_key(username));
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } catch (_) {
      return const {};
    }
  }

  Future<void> writeCookies(
    String username,
    Map<String, String> cookies,
  ) async {
    await SecureStorage.write(_key(username), jsonEncode(cookies));
  }

  Future<void> deleteCookies(String username) async {
    await SecureStorage.delete(_key(username));
  }
}
