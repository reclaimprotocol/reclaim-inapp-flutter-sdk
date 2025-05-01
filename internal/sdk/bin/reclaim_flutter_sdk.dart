// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:reclaim_flutter_sdk/services/capability/access_token.dart';
import 'package:reclaim_flutter_sdk/utils/crypto/signature.dart';
import 'package:reclaim_flutter_sdk/utils/crypto/url_safe_codec.dart';

void printUsage() {
  print('Usage: reclaim_flutter_sdk <genkeys|create|verify> [params]');
}

void printIncorrectUsage(String command, List<String> arguments) {
  print('Usage: reclaim_flutter_sdk $command ${arguments.map((e) => '<$e>').join(' ')}');
}

void main(List<String> args) {
  if (args.isEmpty) {
    printUsage();
    return;
  }
  final command = args[0];
  final params = args.sublist(1);
  switch (command) {
    case 'genkeys':
      return genkeys();
    case 'create':
      return create(params);
    case 'verify':
      return verify(params);
    default:
      print('Invalid command');
      printUsage();
      exit(1);
  }
}

void genkeys() {
  final signer = NistP256ECDSASigner.generate();
  final privateKey = signer.exportPrivateKey();
  final publicKey = signer.exportPublicKey();

  final keys = {
    'keys': [privateKey, publicKey],
  };
  final privateKeyString = urlSafeEncode(utf8.encode(json.encode(privateKey)));
  final publicKeyString = urlSafeEncode(utf8.encode(json.encode(publicKey)));
  final output = json.encode({
    'JWK': keys,
    'privateKeyString': privateKeyString,
    'publicKeyString': publicKeyString,
  });
  print(output);
}

void create(List<String> params) {
  if (params.length != 5) {
    printIncorrectUsage('create', [
      'privateKeyString',
      'subject',
      'expirationInDays',
      'capabilities',
      'authorizedApps',
    ]);
    exit(1);
  }
  final [privateKeyString, sub, expirationInDays, capabilities, authorizedApps] = params;
  final scope = capabilities.split(',').toSet();
  final azp = authorizedApps.split(',').toSet();
  final token = CapabilityAccessToken.create(
    privateKeyString,
    scope,
    azp,
    sub: sub,
    expiresAfter: Duration(days: int.parse(expirationInDays)),
  );
  print(token.accessToken);
}

void verify(List<String> params) {
  if (params.length != 2) {
    printIncorrectUsage('verify', ['publicKeyString', 'accessTokenString']);
    exit(1);
  }
  final [publicKeyString, accessTokenString] = params;
  try {
    final jws = CapabilityAccessToken.import(accessTokenString, publicKeyString);
    print('Valid Signature');
    print(jws.capabilities);
  } on ArgumentError {
    stderr.writeln('Invalid Signature');
  }
}
