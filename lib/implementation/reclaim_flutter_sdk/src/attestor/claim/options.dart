import '../../../types/claim_creation_type.dart';
import '../data/attestor/auth.dart';

class AttestorClaimOptions {
  /// {@macro AttestorAuthenticationRequest}
  final AttestorAuthenticationRequest?
      attestorAuthenticationRequest;

  final ClaimCreationType
      claimCreationType;

  const AttestorClaimOptions({
    this.attestorAuthenticationRequest,
    this.claimCreationType =
        ClaimCreationType.standalone,
  });

  @override
  String
      toString() {
    return 'AttestorClaimOptions(attestorAuthenticationRequest: $attestorAuthenticationRequest)';
  }

  AttestorClaimOptions
      copyWith({
    AttestorAuthenticationRequest?
        attestorAuthenticationRequest,
    ClaimCreationType?
        claimCreationType,
  }) {
    return AttestorClaimOptions(
      attestorAuthenticationRequest:
          attestorAuthenticationRequest ?? this.attestorAuthenticationRequest,
      claimCreationType:
          claimCreationType ?? this.claimCreationType,
    );
  }
}
