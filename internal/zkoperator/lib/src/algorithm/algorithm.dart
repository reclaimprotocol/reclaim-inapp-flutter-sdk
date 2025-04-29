/// Reference:
/// - https://github.com/reclaimprotocol/zk-symmetric-crypto/blob/52ed5d2df1188aa707f30166dfc678242013bf5d/gnark/libraries/prover/impl/library.go#L19
/// - https://github.com/reclaimprotocol/zk-symmetric-crypto/blob/52ed5d2df1188aa707f30166dfc678242013bf5d/gnark/libraries/prover/impl/library.go#L28
enum ProverAlgorithmType {
  CHACHA20(0, 'chacha20', 'chacha20'),
  AES_128(1, 'aes128', 'aes-128-ctr'),
  AES_256(2, 'aes256', 'aes-256-ctr'),
  CHACHA20_OPRF(3, 'chacha20_oprf', 'chacha20-toprf'),
  AES_128_OPRF(4, 'aes128_oprf', 'aes-128-ctr-toprf'),
  AES_256_OPRF(5, 'aes256_oprf', 'aes-256-ctr-toprf');

  static const Set<ProverAlgorithmType> oprf = {CHACHA20_OPRF, AES_128_OPRF, AES_256_OPRF};

  static const Set<ProverAlgorithmType> nonOprf = {CHACHA20, AES_128, AES_256};

  final int id;
  final String key;
  final String name;

  const ProverAlgorithmType(this.id, this.key, this.name);
}
