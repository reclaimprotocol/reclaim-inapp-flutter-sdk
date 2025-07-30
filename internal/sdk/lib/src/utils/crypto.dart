import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:web3dart/crypto.dart';

import '../logging/logging.dart';

String generatePrivateKey() {
  Random rng = Random.secure();

  List<int> key = List<int>.generate(32, (i) => rng.nextInt(256));
  Uint8List keyBytes = Uint8List.fromList(key);

  return bytesToHex(keyBytes, include0x: true);
}

String signMap(Map<String, dynamic> mp, String key) {
  final logger = logging.child('signMap');
  try {
    final hash = keccak256(utf8.encode(json.encode(mp)));

    final String address = EthSigUtil.signPersonalMessage(message: hash, privateKey: key);

    return address;
  } catch (e, s) {
    logger.severe("Error signing map", e, s);
    rethrow;
  }
}
