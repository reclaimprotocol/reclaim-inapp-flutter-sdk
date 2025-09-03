import 'utils/io/io.dart' as io;

interface class BuildEnv {
  static const bool IS_VERIFIER_INAPP_MODULE = bool.fromEnvironment(
    'org.reclaimprotocol.inapp_sdk.IS_VERIFIER_INAPP_MODULE',
    defaultValue: false,
  );
  static const bool IS_CLIENT_LAZY_INITIALIZE = bool.fromEnvironment(
    'org.reclaimprotocol.inapp_sdk.IS_CLIENT_LAZY_INITIALIZE',
    defaultValue: true,
  );
  static const bool MOCK_AI_SERVICE = bool.fromEnvironment(
    'org.reclaimprotocol.inapp_sdk.MOCK_AI_SERVICE',
    defaultValue: false,
  );
  // ignore: non_constant_identifier_names
  static final bool IS_FLUTTER_TEST = io.isFlutterTest;
}
