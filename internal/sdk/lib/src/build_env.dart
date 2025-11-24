// ignore_for_file: non_constant_identifier_names

import 'utils/io/io.dart' as io;

interface class BuildEnv {
  static const bool IS_CLIENT_LAZY_INITIALIZE = bool.fromEnvironment(
    'org.reclaimprotocol.inapp_sdk.IS_CLIENT_LAZY_INITIALIZE',
    defaultValue: true,
  );
  static const bool MOCK_AI_SERVICE = bool.fromEnvironment(
    'org.reclaimprotocol.inapp_sdk.MOCK_AI_SERVICE',
    defaultValue: false,
  );

  static final bool IS_FLUTTER_TEST = io.isFlutterTest;
}

interface class ReclaimEnv {
  static bool IS_VERIFIER_INAPP_MODULE = const bool.fromEnvironment(
    'org.reclaimprotocol.inapp_sdk.IS_VERIFIER_INAPP_MODULE',
    defaultValue: false,
  );
  static String CAPABILITY_ACCESS_TOKEN_VERIFICATION_KEY = const String.fromEnvironment(
    'org.reclaimprotocol.inapp_sdk.CAPABILITY_ACCESS_TOKEN_VERIFICATION_KEY',
  );
}
