interface class BuildEnv {
  static const bool IS_VERIFIER_INAPP_MODULE = bool.fromEnvironment(
    'org.reclaimprotocol.inapp_sdk.IS_VERIFIER_INAPP_MODULE',
    defaultValue: false,
  );
}
