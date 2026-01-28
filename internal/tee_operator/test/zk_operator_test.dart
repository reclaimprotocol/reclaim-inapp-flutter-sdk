import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_tee_operator_flutter/reclaim_tee_operator_flutter.dart';

void main() {
  group('ReclaimZkOperator.isPlatformSupported', () {
    test('isPlatformSupported', () async {
      final operator = ReclaimProxyOperator.instance;
      final supported = operator.isPlatformSupported();
      expect(supported, isTrue);
    });
  });
}
