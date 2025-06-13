import 'package:flutter/foundation.dart';

import '../utils/crypto.dart';
import '../utils/keys.dart';
import '../utils/storage.dart';

@immutable
class UserKeys {
  final String privateKey;
  final String publicKey;
  final Uint8List symmetricKey;

  const UserKeys({required this.privateKey, required this.publicKey, required this.symmetricKey});
}

class ReclaimOwnerKeys {
  Future<String> getReclaimPrivateKeyOfOwner() async {
    const storage = ReclaimStorage();
    final privateKey = await storage.getData('ReclaimOwnerPrivateKey');
    if (privateKey.isEmpty) {
      final generatedPrivateKey = generatePrivateKey();
      await storage.saveData('ReclaimOwnerPrivateKey', generatedPrivateKey);
      return generatedPrivateKey;
    }
    return privateKey;
  }

  Future<UserKeys> getUserKeysFromStorage() async {
    final privateKey = await ReclaimOwnerKeys().getReclaimPrivateKeyOfOwner();
    final publicKey = getPublicKey(privateKey);
    final symmetricKey = deriveSymmetricKey(privateKey);
    return UserKeys(privateKey: privateKey, publicKey: publicKey, symmetricKey: symmetricKey);
  }
}
