import 'dart:convert';

import 'package:jm_manga/network/jm/jm_constants.dart';
import 'package:jm_manga/network/jm/jm_crypto.dart';
import 'package:test/test.dart';

void main() {
  group('JmCrypto', () {
    test('creates mobile api token headers', () {
      final token = JmCrypto.tokenAndTokenParam(1700566805);

      expect(token.token, 'cce2cb071cd0cf371a2e34fd5ad66fd6');
      expect(token.tokenParam, '1700566805,${JmConstants.appVersion}');
    });

    test('uses content secret for scramble endpoint token', () {
      final token = JmCrypto.tokenAndTokenParam(
        1700566805,
        secret: JmConstants.appTokenSecretForContent,
      );

      expect(token.token, '68afe23a1ff9e7a3f9c0a846bbf87e6f');
    });

    test('decrypts AES-256 ECB blocks', () {
      final key = _hex(
        '603deb1015ca71be2b73aef0857d7781'
        '1f352c073b6108d72d9810a30914dff4',
      );
      final encrypted = _hex('f3eed1bdb5d2a03c064b5a7e3db181f8');
      final decrypted = JmCrypto.decryptAesEcb(encrypted, key);

      expect(_hexString(decrypted), '6bc1bee22e409f96e93d7e117393172a');
    });

    test('decodes encrypted response data', () {
      // Plain text is {"ok":true}; encrypted with the JM key derivation for
      // timestamp 1700566805 and PKCS#7 padding.
      const encrypted = '6wltmcZn1K6+caAkfWitng==';

      final decoded = JmCrypto.decodeResponseData(encrypted, 1700566805);

      expect(jsonDecode(decoded), {'ok': true});
    });

    test('decodes domain server config with empty timestamp secret', () {
      // Plain text is {"Server":["www.example.com"]}; encrypted with the
      // domain-server secret and PKCS#7 padding.
      const encrypted = 'kZ6NO8GbIErWjL6mCv5qIA+0TEAX4iq8CsdPdviFKjI=';

      final decoded = JmCrypto.decodeDomainServerData(encrypted);

      expect(jsonDecode(decoded), {'Server': ['www.example.com']});
    });
  });
}

List<int> _hex(String value) {
  final bytes = <int>[];
  for (var i = 0; i < value.length; i += 2) {
    bytes.add(int.parse(value.substring(i, i + 2), radix: 16));
  }
  return bytes;
}

String _hexString(List<int> bytes) {
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}
