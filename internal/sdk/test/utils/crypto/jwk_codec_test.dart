import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_inapp_sdk/src/utils/crypto/jwk_codec.dart';

void main() {
  group('JwkValueCodec', () {
    final codec = JwkValueCodec();

    test('should encode and decode BigInt', () {
      final value = BigInt.from(1234567890);
      final encoded = codec.encode(value);
      final decoded = codec.decode(encoded);
      expect(encoded, 'SZYC0g');
      expect(decoded, value);
    });

    test('should encode and decode BigInt with large numbers', () {
      final value = BigInt.parse('39652107780440097616261701677477693488465820838769261154713640144338514325440');
      final encoded = codec.encode(value);
      final decoded = codec.decode(encoded);
      expect(encoded, 'V6pMNKtWkU2z_OJ5hxMkUv2UzOaUt-4mdKRVZwzjr8A');
      expect(decoded, value);
    });
  });
}
