import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/models/jm_account.dart';

void main() {
  group('JmAccount', () {
    test('generates id when not provided', () {
      final account = JmAccount(username: 'alice');
      expect(account.id, isNotEmpty);
      expect(account.id.length, greaterThan(10));
    });

    test('preserves provided id', () {
      final account = JmAccount(id: 'custom-id', username: 'alice');
      expect(account.id, 'custom-id');
    });

    test('displayName for anonymous account', () {
      final account = JmAccount(isAnonymous: true);
      expect(account.displayName, 'Anonymous');
    });

    test('displayName falls back to username', () {
      final account = JmAccount(username: 'alice');
      expect(account.displayName, 'alice');
    });

    test('displayName falls back to Unknown', () {
      final account = JmAccount();
      expect(account.displayName, 'Unknown');
    });

    test('copyWith preserves id and updates fields', () {
      final account = JmAccount(
        id: 'id1',
        username: 'alice',
        password: 'secret',
        isAnonymous: false,
      );

      final updated = account.copyWith(password: 'new-secret');

      expect(updated.id, 'id1');
      expect(updated.username, 'alice');
      expect(updated.password, 'new-secret');
      expect(updated.isAnonymous, isFalse);
    });

    test('toPublicJson excludes password', () {
      final account = JmAccount(
        id: 'id1',
        username: 'alice',
        password: 'secret',
      );

      final json = account.toPublicJson();
      expect(json['id'], 'id1');
      expect(json['username'], 'alice');
      expect(json.containsKey('password'), isFalse);
    });

    test('fromJson parses public fields', () {
      final account = JmAccount.fromJson({
        'id': 'id1',
        'username': 'alice',
        'isAnonymous': true,
      });

      expect(account.id, 'id1');
      expect(account.username, 'alice');
      expect(account.isAnonymous, isTrue);
    });

    test('fromJson defaults isAnonymous to false', () {
      final account = JmAccount.fromJson({'username': 'alice'});
      expect(account.isAnonymous, isFalse);
    });
  });
}
