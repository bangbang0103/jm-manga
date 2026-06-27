import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/models/jm_account.dart';
import 'package:jm_manga/utils/account_secret_store.dart';

void main() {
  group('AccountSecretStore', () {
    test(
      'clearAccountSecrets removes password and session cookie keys',
      () async {
        FlutterSecureStorage.setMockInitialValues({
          'jm_account_password_abc': 'secret',
          'jm_session_cookies_alice': '{"AVS":"x"}',
        });

        await AccountSecretStore.clearAccountSecrets(
          JmAccount(id: 'abc', username: 'alice'),
        );

        const storage = FlutterSecureStorage();
        expect(await storage.read(key: 'jm_account_password_abc'), isNull);
        expect(await storage.read(key: 'jm_session_cookies_alice'), isNull);
      },
    );

    test(
      'clearAccountSecrets skips cookie key when username is null',
      () async {
        FlutterSecureStorage.setMockInitialValues({
          'jm_account_password_def': 'secret',
        });

        await AccountSecretStore.clearAccountSecrets(
          JmAccount(id: 'def', isAnonymous: true),
        );

        const storage = FlutterSecureStorage();
        expect(await storage.read(key: 'jm_account_password_def'), isNull);
      },
    );
  });
}
