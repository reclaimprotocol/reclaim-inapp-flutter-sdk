import 'algorithm.dart';

// https://github.com/reclaimprotocol/zk-symmetric-crypto/raw/refs/heads/main/resources/gnark
const _gnarkAssetBaseUrl = 'https://d5znggfgtutzp.cloudfront.net';

extension ProverAlgorithmTypeAssets on ProverAlgorithmType {
  String get defaultKeyAssetUrl => '$_gnarkAssetBaseUrl/pk.$key';
  String get defaultR1CSAssetUrl => '$_gnarkAssetBaseUrl/r1cs.$key';
}
