import 'dart:convert';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:reclaim_gnark_zkoperator/src/utils/list.dart';

import 'algorithm.dart';

final _logger = Logger('reclaim_flutter_sdk.reclaim_gnark_zkoperator.algorithm.utils');

final _nameToBytes = <ProverAlgorithmType, Uint8List>{};
final _keyToBytes = <ProverAlgorithmType, Uint8List>{};

extension _IdBytes on ProverAlgorithmType {
  Uint8List nameToBytes() {
    return _nameToBytes[this] ??= utf8.encode(name);
  }

  Uint8List keyToBytes() {
    return _keyToBytes[this] ??= utf8.encode(key);
  }
}

final _orderedAlgorithmTypes = [...ProverAlgorithmType.oprf, ...ProverAlgorithmType.nonOprf];

ProverAlgorithmType? identifyAlgorithmFromZKOperationRequest(Uint8List bytes) {
  try {
    for (final algorithm in _orderedAlgorithmTypes) {
      // check if the request bytes contain the algorithm name or key
      if (hasSubview(bytes, algorithm.nameToBytes())) {
        return algorithm;
      }
      if (hasSubview(bytes, algorithm.keyToBytes())) {
        return algorithm;
      }
    }
    _logger.finest('no algorithm found in request bytes with hasSubview');
    // fallback to json decoding the request bytes
    final request = json.decode(utf8.decode(bytes));
    var requestAlgorithm = request['cipher'];
    if (requestAlgorithm is! String || requestAlgorithm.isEmpty) {
      return null;
    }
    requestAlgorithm = requestAlgorithm.trim();
    for (final algorithm in ProverAlgorithmType.values) {
      if (algorithm.name.toLowerCase() == requestAlgorithm) {
        return algorithm;
      }
      if (algorithm.key.toLowerCase() == requestAlgorithm) {
        return algorithm;
      }
    }
  } catch (e, s) {
    _logger.severe('Error identifying algorithm from zk operation request', e, s);
  }
  return null;
}
