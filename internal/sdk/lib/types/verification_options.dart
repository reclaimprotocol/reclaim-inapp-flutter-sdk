import 'dart:async';

import 'package:reclaim_flutter_sdk/data/providers.dart' show HttpProvider;
import 'package:reclaim_flutter_sdk/src/attestor/data/attestor/auth.dart' show AttestorAuthenticationRequest;

typedef ReclaimAttestorAuthenticationRequestCallback = FutureOr<AttestorAuthenticationRequest> Function(
  HttpProvider provider,
);
typedef CanContinueVerificationCallback = Future<bool> Function(HttpProvider provider);

class ReclaimVerificationOptions {
  /// {@template ReclaimVerificationOptions.preventCookieDeletion}
  /// Whether to prevent cookie deletion.
  /// {@endtemplate}
  final bool? preventCookieDeletion;

  /// A callback that returns an authentication request when a Reclaim HTTP provider is provided.
  /// {@macro AttestorAuthenticationRequest}
  final ReclaimAttestorAuthenticationRequestCallback? attestorAuthenticationRequest;

  /// A callback that returns a boolean value indicating whether the verification can continue.
  final CanContinueVerificationCallback? canContinueVerification;

  ReclaimVerificationOptions({
    this.preventCookieDeletion = false,
    this.attestorAuthenticationRequest,
    this.canContinueVerification,
  });
}
