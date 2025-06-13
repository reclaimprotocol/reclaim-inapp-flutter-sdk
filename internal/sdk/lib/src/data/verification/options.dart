import 'dart:async';

import '../../attestor/data/attestor/auth.dart' show AttestorAuthenticationRequest;
import '../../attestor/operator/operator.dart';
import '../claim_creation_type.dart';
import '../providers.dart';
import '../session.dart';

export 'package:reclaim_inapp_sdk/src/attestor/data/attestor/auth.dart' show AttestorAuthenticationRequest;
export 'package:reclaim_inapp_sdk/src/attestor/operator/operator.dart';
export 'package:reclaim_inapp_sdk/src/data/claim_creation_type.dart';
export 'package:reclaim_inapp_sdk/src/data/session.dart';

typedef ReclaimAttestorAuthenticationRequestCallback =
    FutureOr<AttestorAuthenticationRequest> Function(HttpProvider provider);

typedef CanContinueVerificationCallback =
    Future<bool> Function(HttpProvider provider, ReclaimSessionInformation sessionInformation);

class ReclaimVerificationOptions {
  final bool canAutoSubmit;
  final bool isCloseButtonVisible;
  final ClaimCreationType claimCreationType;

  /// {@template ReclaimVerificationOptions.canClearWebStorage}
  /// Whether to clear webview's storage before starting the verification.
  /// {@endtemplate}
  final bool canClearWebStorage;

  /// A callback that returns an authentication request when a Reclaim HTTP provider is provided.
  /// {@macro AttestorAuthenticationRequest}
  final ReclaimAttestorAuthenticationRequestCallback? attestorAuthenticationRequest;

  /// A callback that returns a boolean value indicating whether the verification can continue.
  final CanContinueVerificationCallback? canContinueVerification;

  /// A custom [AttestorZkOperator] to be used for the verification.
  final AttestorZkOperator? attestorZkOperator;

  const ReclaimVerificationOptions({
    this.canAutoSubmit = false,
    this.isCloseButtonVisible = true,
    this.claimCreationType = ClaimCreationType.standalone,
    this.canClearWebStorage = true,
    this.attestorAuthenticationRequest,
    this.canContinueVerification,
    this.attestorZkOperator,
  });

  ReclaimVerificationOptions copyWith({
    bool? canAutoSubmit,
    bool? isCloseButtonVisible,
    ClaimCreationType? claimCreationType,
    bool? canClearWebStorage,
    ReclaimAttestorAuthenticationRequestCallback? attestorAuthenticationRequest,
    CanContinueVerificationCallback? canContinueVerification,
    AttestorZkOperator? attestorZkOperator,
  }) {
    return ReclaimVerificationOptions(
      canAutoSubmit: canAutoSubmit ?? this.canAutoSubmit,
      isCloseButtonVisible: isCloseButtonVisible ?? this.isCloseButtonVisible,
      claimCreationType: claimCreationType ?? this.claimCreationType,
      canClearWebStorage: canClearWebStorage ?? this.canClearWebStorage,
      attestorAuthenticationRequest: attestorAuthenticationRequest ?? this.attestorAuthenticationRequest,
      canContinueVerification: canContinueVerification ?? this.canContinueVerification,
      attestorZkOperator: attestorZkOperator ?? this.attestorZkOperator,
    );
  }
}
