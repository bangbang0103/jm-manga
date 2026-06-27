import '../network/jm/jm_session_store.dart';
import '../models/jm_account.dart';
import 'secure_storage.dart';

/// 集中管理账号级敏感数据的清理。
///
/// 账号被删除时，需要同时清理 password、JM session cookie 等分散在
/// SecureStorage 中的 key。
class AccountSecretStore {
  static String _passwordKey(String id) => 'jm_account_password_$id';

  static Future<void> clearAccountSecrets(JmAccount account) async {
    await SecureStorage.delete(_passwordKey(account.id));
    final username = account.username?.trim();
    if (username != null && username.isNotEmpty) {
      await const JmSessionStore().deleteCookies(username);
    }
  }
}
