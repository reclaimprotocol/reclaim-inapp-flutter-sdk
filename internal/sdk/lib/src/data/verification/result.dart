import '../create_claim.dart';
import '../providers.dart';

class ReclaimVerificationResult {
  final HttpProvider provider;
  final String exactProviderVersion;
  final List<CreateClaimOutput> proofs;

  const ReclaimVerificationResult({required this.provider, required this.proofs, required this.exactProviderVersion});
}
