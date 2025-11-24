import 'algorithm.dart';

const _gnarkAssetMirrors = [
  // https://github.com/reclaimprotocol/zk-symmetric-crypto/raw/refs/heads/6dc70dce6c8ea8a342fe740bf7e2cf91db97f3c3/resources/gnark
  'https://d5znggfgtutzp.cloudfront.net/operator-circuits-v3',
  'https://reclaim-gnark-assets.rough-hat-079e.workers.dev/operator-circuits-v3',
  'https://github.com/reclaimprotocol/zk-symmetric-crypto/raw/refs/heads/6dc70dce6c8ea8a342fe740bf7e2cf91db97f3c3/resources/gnark',
];

extension ProverAlgorithmTypeAssets on ProverAlgorithmType {
  List<String> get defaultKeyAssetUrls {
    return _gnarkAssetMirrors.map((e) => '$e/pk.$key').toList();
  }

  List<String> get defaultR1CSAssetUrls {
    return _gnarkAssetMirrors.map((e) => '$e/r1cs.$key').toList();
  }
}
