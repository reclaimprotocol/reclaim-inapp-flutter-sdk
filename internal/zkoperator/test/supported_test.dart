import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_gnark_zkoperator/reclaim_gnark_zkoperator.dart';

void main() {
  group('ReclaimZkOperator.isPlatformSupported', () {
    test('isPlatformSupported', () async {
      final operator = await ReclaimZkOperator.getInstance();
      final supported = await operator.isPlatformSupported();
      expect(supported, isTrue);
    });
  });
}
