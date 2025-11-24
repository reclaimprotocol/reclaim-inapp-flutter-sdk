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
  static const String DIAGNOSTIC_LOGGING = String.fromEnvironment(
    'org.reclaimprotocol.inapp_sdk.DIAGNOSTIC_LOGGING_API',
    defaultValue: '$LOGS_API_BASE_URL/api/business-logs/logDump',
  );
  static const String DEFAULT_CALLBACK_URL_PATH = '$SDK_API_BASE_URL/api/sdk/callback';
  static const String AI_SERVICE_BASE_URL = 'https://service.reclaimprotocol.org/api';
  static const String AI_SERVICE_SEND_EVENTS = '$AI_SERVICE_BASE_URL/network-requests/add-to-queue';
  static const String AI_SERVICE_GET_AI_RESPONSE = '$AI_SERVICE_BASE_URL/ai-actions';
  static String getApplicationProviderUrl(String appId, String providerId) {
    return '$SDK_API_BASE_URL/api/applications/$appId/provider/$providerId';
  }

  static const String PRIVACY_POLICY_URL =
      'https://reclaimprotocol.notion.site/Privacy-Policy-Reclaim-Protocol-115275b816cb80ab94b8ca8616673658';
  static const String TERMS_OF_SERVICE_URL =
      'https://reclaimprotocol.notion.site/Terms-of-Service-Reclaim-Protocol-13c275b816cb80b1a5ade76c6f2532dd';
  static const String POTENTIAL_FAILURE_REASONS_URL =
      'https://reclaimprotocol.notion.site/Potential-Failure-Reasons-Reclaim-Protocol-242275b816cb80d08d35c1dd13a83d39';
}

final templateParamRegex = RegExp(r'{{(.*?)}}');
final regexTemplateParamRegex = RegExp(r'\?<(.*?)>');
