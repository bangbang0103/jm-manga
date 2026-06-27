import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 敏感凭据加密存储封装。
///
/// 用于替代 SharedPreferences 保存 token、password 等高价值字段。
/// 所有操作都捕获原生异常，避免 KeyStore/Keychain 异常导致启动崩溃。
class SecureStorage {
  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  static const FlutterSecureStorage _instance = FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );

  static FlutterSecureStorage get instance => _instance;

  static Future<String?> read(String key) async {
    try {
      return await _instance.read(key: key);
    } catch (e, st) {
      debugPrint('SecureStorage read failed: $e\n$st');
      return null;
    }
  }

  static Future<void> write(String key, String? value) async {
    try {
      if (value == null || value.isEmpty) {
        await _instance.delete(key: key);
      } else {
        await _instance.write(key: key, value: value);
      }
    } catch (e, st) {
      debugPrint('SecureStorage write failed: $e\n$st');
    }
  }

  static Future<void> delete(String key) async {
    try {
      await _instance.delete(key: key);
    } catch (e, st) {
      debugPrint('SecureStorage delete failed: $e\n$st');
    }
  }
}
