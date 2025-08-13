import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../logging/logging.dart';
import 'crypto/ethers.dart';

String generatePrivateKey() {
  Random rng = Random.secure();

  List<int> key = List<int>.generate(32, (i) => rng.nextInt(256));
  Uint8List keyBytes = Uint8List.fromList(key);

  return CryptoEthers.bytesToHex(keyBytes, include0x: true);
}

String signMap(Map<String, dynamic> mp, String key) {
  final logger = logging.child('signMap');
  try {
    final hash = keccak256(utf8.encode(json.encode(mp)));

    final String address = CryptoEthers.signPersonalMessage(message: hash, privateKey: key);

    return address;
  } catch (e, s) {
    logger.severe("Error signing map", e, s);
    rethrow;
  }
}
