import 'dart:convert';

import '../create_claim.dart';
import '../providers.dart';

class ReclaimVerificationResult {
  final HttpProvider provider;
  final String exactProviderVersion;
  final List<CreateClaimOutput> proofs;

  const ReclaimVerificationResult({required this.provider, required this.proofs, required this.exactProviderVersion});

  Map<String, Object?> toJson() {
    return {'provider': provider, 'exactProviderVersion': exactProviderVersion, 'proofs': proofs};
  }

  @override
  String toString() {
    return 'ReclaimVerificationResult(${json.encode(toJson())})';
  }
}
