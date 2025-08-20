import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:pointycastle/export.dart';

import 'crypto/ethers.dart';

String getPublicKey(String privateKeyHex) {
  final publicKey = extractPublicKey(privateKeyHex);
  final ethereumAddress = deriveEthereumAddress(publicKey);
  return ethereumAddress;
}

String extractPublicKey(String privateKeyHex) {
  if (privateKeyHex.isEmpty) return '';
  privateKeyHex = privateKeyHex.substring(2);

  final privateKeyValue = BigInt.parse(privateKeyHex, radix: 16);
  final domainParams = ECDomainParameters('secp256k1');
  final privateKey = ECPrivateKey(privateKeyValue, domainParams);

  final publicKeyPoint = domainParams.G * privateKey.d!;

  final xCoordinate = publicKeyPoint?.x?.toBigInteger() ?? BigInt.zero;
  final yCoordinate = publicKeyPoint?.y?.toBigInteger() ?? BigInt.zero;

  String uncompressedPublicKey =
      xCoordinate.toRadixString(16).padLeft(64, '0') + yCoordinate.toRadixString(16).padLeft(64, '0');

  return uncompressedPublicKey;
}

String deriveEthereumAddress(String publicKeyHex) {
  Uint8List publicKeyBytes = hexToBytes(publicKeyHex);

  Uint8List keccakHash = keccak256(publicKeyBytes);

  String ethereumAddress =
      '0x${keccakHash.sublist(keccakHash.length - 20).map((byte) {
        return byte.toRadixString(16).padLeft(2, '0');
      }).join()}';

  return ethereumAddress;
}

Uint8List hexToBytes(String hex) {
  return Uint8List.fromList(
    List.generate(hex.length ~/ 2, (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16)),
  );
}

String bytesToHex(Uint8List bytes) {
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}

Uint8List deriveSymmetricKey(String privateKey) {
  final privateKeyBytes = utf8.encode(privateKey);
  final sha256Digest = crypto.sha256.convert(Uint8List.fromList(privateKeyBytes));
  return Uint8List.fromList(sha256Digest.bytes);
}
