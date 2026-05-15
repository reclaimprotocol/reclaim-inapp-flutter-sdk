sealed class ReclaimUrls {
  static const String SDK_API_BASE_URL = String.fromEnvironment(
    'org.reclaimprotocol.inapp_sdk.SDK_API_BASE_URL',
    defaultValue: 'https://api.reclaimprotocol.org',
  );
  static const String LOGS_API_BASE_URL = String.fromEnvironment(
    'org.reclaimprotocol.inapp_sdk.LOGS_API_BASE_URL',
    defaultValue: 'https://logs.reclaimprotocol.org',
  );
  static const String SESSION_URL = '$SDK_API_BASE_URL/api/sdk/update/session';
  static const String SESSION_INIT = '$SDK_API_BASE_URL/api/sdk/init/session';
  static const String MANUAL_VERIFICATION_PREFIX = '$SDK_API_BASE_URL/api/manual-verification';
  static const String LOGS_API = '$LOGS_API_BASE_URL/api/business-logs/app';
  static const String FEATURE_FLAGS_API = '$SDK_API_BASE_URL/api/feature-flags';
  static const String DEFAULT_ATTESTOR_WEB_URL = 'https://attestor.reclaimprotocol.org:444/browser-rpc';
  // NOTES:
  // - Includes a version or hash in query params to force update cache when updated script
  // - Last updated copy was hosted at: https://reclaim-inapp-sdk.s3.ap-south-1.amazonaws.com/attestor-jsc.min.mjs?v=0
  // TODO: Change to default production url when we have it
  static const String DEFAULT_ATTESTOR_WEB_SCRIPT_URL = '$DEFAULT_ATTESTOR_WEB_URL/resources/attestor-jsc.min.mjs?v=0';

  // TEE (Trusted Execution Environment) URLs
  static const String DEFAULT_TEEK_WS_URL = 'wss://tk.reclaimprotocol.org/ws';
  static const String DEFAULT_TEET_WS_URL = 'wss://tt.reclaimprotocol.org/ws';
  static const String DEFAULT_TEE_ATTESTOR_WS_URL = 'wss://tee-attestor.reclaimprotocol.org/ws';

  static const String DIAGNOSTIC_LOGGING = String.fromEnvironment(
    'org.reclaimprotocol.inapp_sdk.DIAGNOSTIC_LOGGING_API',
    defaultValue: '$LOGS_API_BASE_URL/api/business-logs/logDump',
  );
  static const String DEFAULT_CALLBACK_URL_PATH = '$SDK_API_BASE_URL/api/sdk/callback';
  static String getErrorCallbackUrl(String sessionId) =>
      '$SDK_API_BASE_URL/api/sdk/error-callback?callbackId=$sessionId';
  static const String AI_SERVICE_BASE_URL = 'https://service.reclaimprotocol.org/api';
  static const String AI_SERVICE_SEND_EVENTS = '$AI_SERVICE_BASE_URL/network-requests/add-to-queue';
  static const String AI_SERVICE_GET_AI_RESPONSE = '$AI_SERVICE_BASE_URL/ai-actions';
  static String getApplicationProviderUrl(String appId, String providerId) {
    return '$SDK_API_BASE_URL/api/applications/$appId/provider/$providerId';
  }

  static const String PRIVACY_POLICY_URL = 'https://docs.reclaimprotocol.org/legalese/privacy-policy';
  static const String TERMS_OF_SERVICE_URL = 'https://docs.reclaimprotocol.org/legalese/terms-of-service';
  static const String POTENTIAL_FAILURE_REASONS_URL =
      'https://docs.reclaimprotocol.org/troubleshooting/potential-failure-reasons';
}

final templateParamRegex = RegExp(r'{{(.*?)}}');
final regexTemplateParamRegex = RegExp(r'\?<(.*?)>');
