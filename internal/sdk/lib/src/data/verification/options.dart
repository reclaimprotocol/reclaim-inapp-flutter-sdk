import 'dart:async';

import '../../attestor/data/attestor/auth.dart' show AttestorAuthenticationRequest;
import '../claim_creation_type.dart';
import '../providers.dart';
import '../session.dart';

export 'package:reclaim_inapp_sdk/src/attestor/data/attestor/auth.dart' show AttestorAuthenticationRequest;
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

  /// {@template ReclaimVerificationOptions.useTeeOperator}
  /// Enables use of Reclaim's TEE+MPC protocol for HTTP Request claim verification and
  /// attestation.
  ///
  /// When set to `true`, the verification will use Trusted Execution Environment
  /// (TEE) with Multi-Party Computation (MPC) for enhanced security.
  ///
  /// When set to `false`, the standard Reclaim's proxy attestor verification flow is used.
  ///
  /// When `null` (default), the backend decides whether to use TEE based on
  /// a feature flag (currently in staged rollout).
  /// {@endtemplate}
  final bool? useTeeOperator;

  /// A language code & Country code for localization that should be enforced in the verification flow.
  final String? locale;

  /// A custom URL to which error callbacks will be sent when verification fails.
  /// If null, the default SDK error callback URL is used.
  final String? errorCallbackUrl;

  const ReclaimVerificationOptions({
    this.canAutoSubmit = false,
    this.isCloseButtonVisible = true,
    this.claimCreationType = ClaimCreationType.standalone,
    this.canClearWebStorage = true,
    this.attestorAuthenticationRequest,
    this.canContinueVerification,
    this.useTeeOperator,
    this.locale,
    this.errorCallbackUrl,
  });

  ReclaimVerificationOptions copyWith({
    bool? canAutoSubmit,
    bool? isCloseButtonVisible,
    ClaimCreationType? claimCreationType,
    bool? canClearWebStorage,
    ReclaimAttestorAuthenticationRequestCallback? attestorAuthenticationRequest,
    CanContinueVerificationCallback? canContinueVerification,
    bool? useTeeOperator,
    String? locale,
    String? errorCallbackUrl,
  }) {
    return ReclaimVerificationOptions(
      canAutoSubmit: canAutoSubmit ?? this.canAutoSubmit,
      isCloseButtonVisible: isCloseButtonVisible ?? this.isCloseButtonVisible,
      claimCreationType: claimCreationType ?? this.claimCreationType,
      canClearWebStorage: canClearWebStorage ?? this.canClearWebStorage,
      attestorAuthenticationRequest: attestorAuthenticationRequest ?? this.attestorAuthenticationRequest,
      canContinueVerification: canContinueVerification ?? this.canContinueVerification,
      useTeeOperator: useTeeOperator ?? this.useTeeOperator,
      locale: locale ?? this.locale,
      errorCallbackUrl: errorCallbackUrl ?? this.errorCallbackUrl,
    );
  }
}
