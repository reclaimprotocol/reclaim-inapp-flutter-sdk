import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_flutter_sdk/src/utils/sanitize.dart';

void main() {
  group('sanitize', () {
    test('ensureMap', () {
      expect(ensureMap<String, String>({'a': 'b'}), const <String, String>{'a': 'b'});
      expect(ensureMap<String, String>({'a': 'b', 'c': 'd'}), const <String, String>{'a': 'b', 'c': 'd'});
      expect(ensureMap<String, String>({'a': 'b', 'c': 'd'}), const <String, String>{'a': 'b', 'c': 'd'});
    });
  });
}