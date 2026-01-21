import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_tee_operator_flutter/reclaim_tee_operator_flutter.dart';
import 'package:reclaim_tee_operator_flutter/src/common/algorithm/utils.dart';

void main() {
  group('identifyAlgorithmFromZKOperationRequest', () {
    for (final algorithm in ProverAlgorithmType.values) {
      test(algorithm.name, () {
        final algorithmNameJsonStringBytes = utf8.encode('"${algorithm.name}"');
        expect(identifyAlgorithmFromZKOperationRequest(algorithmNameJsonStringBytes), algorithm);
        expect(algorithm.nameToJsonStringBytes(), algorithmNameJsonStringBytes);
      });
    }
  });
}
