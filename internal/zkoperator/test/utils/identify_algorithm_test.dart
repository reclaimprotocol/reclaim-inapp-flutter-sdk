import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_gnark_zkoperator/reclaim_gnark_zkoperator.dart';
import 'package:reclaim_gnark_zkoperator/src/algorithm/utils.dart';

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
