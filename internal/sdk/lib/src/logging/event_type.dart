/// Enum representing different types of logging events in the Reclaim SDK.
enum LogEventType {
  /// The verification flow has been initiated by the user.
  VERIFICATION_FLOW_STARTED,

  /// Checking if the current environment is a Reclaim verifier.
  IS_RECLAIM_VERIFIER,

  /// An update for inapp SDK is available. Use is still allowed.
  UPDATE_AVAILABLE,

  /// An update for inapp SDK is available and the current version cannot be used anymore.
  SDK_OUTDATED,

  /// An exception indicating that the platform is not supported for Reclaim verification.
  RECLAIM_VERIFICATION_PLATFORM_NOT_SUPPORTED_EXCEPTION,

  /// An exception for an invalid Reclaim request.
  INVALID_REQUEST_RECLAIM_EXCEPTION,

  /// The Reclaim verification process was dismissed by the user.
  RECLAIM_VERIFICATION_DISMISSED,

  /// An exception indicating the user cancelled the verification process.
  RECLAIM_VERIFICATION_CANCELLED_EXCEPTION,

  /// An exception during the loading of a verification provider.
  RECLAIM_VERIFICATION_PROVIDER_LOAD_EXCEPTION,

  /// An exception when initializing a Reclaim session.
  RECLAIM_INIT_SESSION_EXCEPTION,

  /// An exception for an expired Reclaim session.
  RECLAIM_EXPIRED_SESSION_EXCEPTION,

  /// The Reclaim verification process was skipped.
  RECLAIM_VERIFICATION_SKIPPED,

  /// An exception related to attestor authentication.
  RECLAIM_ATTESTOR_AUTH_EXCEPTION,

  /// The web page for verification is ready.
  WEB_PAGE_READY,

  /// An exception when no user activity is detected during verification.
  RECLAIM_VERIFICATION_NO_ACTIVITY_DETECTED_EXCEPTION,

  /// A network request has been intercepted.
  REQUEST_INTERCEPTED,

  /// A network request has been matched against the provider's requirements.
  REQUEST_MATCHED,

  /// The provider script has requested a claim.
  PROVIDER_SCRIPT_REQUESTED_CLAIM,

  /// The claim is being prepared.
  PREPARING_CLAIM,

  /// The claim parameters are being validated.
  VALIDATING_CLAIM_PARAMETERS,

  /// An XPath match requirement for claim validation has failed.
  X_PATH_MATCH_REQUIREMENT_FAILED,

  /// A JSONPath match requirement for claim validation has failed.
  JSON_PATH_MATCH_REQUIREMENT_FAILED,

  /// A regex match requirement for claim validation has failed.
  REGEX_MATCH_REQUIREMENT_FAILED,

  ///
  NO_PARAMETERS_FOUND,

  /// An exception for failed claim parameter validation.
  CLAIM_PARAMETER_VALIDATION_FAILED_EXCEPTION,

  /// A warning that no response matched the provider's requirements.
  NO_RESPONSE_MATCH_WARNING,

  /// The process of creating a claim is starting.
  STARTING_CLAIM_CREATION,

  /// The claim creation process has officially started.
  CLAIM_CREATION_STARTED,

  /// The attestor is not responding.
  ATTESTOR_NOT_RESPONDING,

  /// An exception indicating the claim creation was cancelled.
  CLAIM_CREATION_CANCELLED_EXCEPTION,

  /// A proof has been successfully generated.
  PROOF_GENERATED,

  /// An exception for a failed proof generation.
  PROOF_GENERATION_FAILED_EXCEPTION,

  /// An exception indicating that the claim creation process has timed out.
  CLAIM_CREATION_TIMED_OUT_EXCEPTION,

  /// A result has been received.
  RESULT_RECEIVED,

  /// The generated proof is being submitted.
  SUBMITTING_PROOF,

  /// The proof has been successfully submitted.
  PROOF_SUBMITTED,

  /// The proof submission has failed.
  PROOF_SUBMISSION_FAILED,
}
