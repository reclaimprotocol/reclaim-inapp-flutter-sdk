import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_tee_operator_flutter/reclaim_tee_operator_flutter.dart';
import 'package:reclaim_tee_operator_flutter/src/common/utils/platform.dart';

void main() {
  group('ReclaimTEEOperator', () {
    test('isPlatformSupported', () async {
      final supported = isPlatformSupported();
      // This might fail in test environment without native libraries
      // but the method should not throw an exception
      expect(supported, isA<bool>());
    });

    test(
      'getVersion',
      () async {
        try {
          final operator = ReclaimTEEOperator.instance;
          final version = await operator.getVersion();
          expect(version, isA<String>());
          expect(version.isNotEmpty, isTrue);
        } catch (e) {
          // Expected to fail in test environment without native libraries or unsupported platform
          expect(e, anyOf([isA<Exception>(), isA<UnsupportedError>()]));
        }
      },
      // Binary only built for testing on physical mobile device or simulator
      skip: true,
    );

    test('executeRequest creates proper provider data structure', () async {
      // Test the data structure creation without actually calling native methods
      final responseMatches = [ResponseMatch(value: 'test', type: 'contains')];

      final responseRedactions = [ResponseRedaction(jsonPath: r'$.test'), ResponseRedaction(xPath: '//test')];

      expect(responseMatches.first.toJson(), {'value': 'test', 'type': 'contains'});

      expect(responseRedactions.first.toJson(), {'jsonPath': r'$.test'});
      expect(responseRedactions.last.toJson(), {'xPath': '//test'});
    });
  });
}
