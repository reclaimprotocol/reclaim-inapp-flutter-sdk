import 'package:reclaim_flutter_sdk/src/attestor/data/attestor/auth.dart';
import 'package:reclaim_flutter_sdk/types/claim_creation_type.dart';

class AttestorClaimOptions {
  /// {@macro AttestorAuthenticationRequest}
  final AttestorAuthenticationRequest? attestorAuthenticationRequest;

  final ClaimCreationType claimCreationType;

  const AttestorClaimOptions({
    this.attestorAuthenticationRequest,
    this.claimCreationType = ClaimCreationType.standalone,
  });

  @override
  String toString() {
    return 'AttestorClaimOptions(attestorAuthenticationRequest: $attestorAuthenticationRequest)';
  }

  AttestorClaimOptions copyWith({
    AttestorAuthenticationRequest? attestorAuthenticationRequest,
    ClaimCreationType? claimCreationType,
  }) {
    return AttestorClaimOptions(
      attestorAuthenticationRequest:
          attestorAuthenticationRequest ?? this.attestorAuthenticationRequest,
      claimCreationType: claimCreationType ?? this.claimCreationType,
    );
  }
}
