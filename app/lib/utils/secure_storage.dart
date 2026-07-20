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
  // macOS 发布包为 ad-hoc 签名（无开发团队），data-protection keychain 依赖
  // keychain-access-groups entitlement 与团队前缀，ad-hoc 下不可用（-34018）；
  // 退回文件型 login keychain，沙盒内无需额外 entitlement。
  static const _macosOptions = MacOsOptions(useDataProtectionKeyChain: false);

  static const FlutterSecureStorage _instance = FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
    mOptions: _macosOptions,
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
