sealed class ReclaimUrls {
  static const String SDK_API_BASE_URL = String.fromEnvironment(
    'org.reclaimprotocol.inapp_sdk.SDK_API_BASE_URL',
    defaultValue: 'https://api.reclaimprotocol.org',
  );
  static const String SESSION_URL = '$SDK_API_BASE_URL/api/sdk/update/session';
  static const String SESSION_INIT = '$SDK_API_BASE_URL/api/sdk/init/session';
  static const String MANUAL_VERIFICATION_PREFIX = '$SDK_API_BASE_URL/api/manual-verification';
  static const String LOGS_API = 'https://logs.reclaimprotocol.org/api/business-logs/app';
  static const String FEATURE_FLAGS_API = '$SDK_API_BASE_URL/api/feature-flags';
  static const String DEFAULT_ATTESTOR_WEB_URL = 'https://attestor.reclaimprotocol.org/browser-rpc';
  static const String DIAGNOSTIC_LOGGING = String.fromEnvironment(
    'org.reclaimprotocol.inapp_sdk.DIAGNOSTIC_LOGGING_API',
    defaultValue: 'https://logs.reclaimprotocol.org/api/business-logs/logDump',
  );
  static const String DEFAULT_CALLBACK_URL_PATH = '$SDK_API_BASE_URL/api/sdk/callback';
  static String getApplicationProviderUrl(String appId, String providerId) {
    return '$SDK_API_BASE_URL/api/applications/$appId/provider/$providerId';
  }

  static const String PRIVACY_POLICY_URL =
      'https://reclaimprotocol.notion.site/Privacy-Policy-Reclaim-Protocol-115275b816cb80ab94b8ca8616673658';
  static const String TERMS_OF_SERVICE_URL =
      'https://reclaimprotocol.notion.site/Terms-of-Service-Reclaim-Protocol-13c275b816cb80b1a5ade76c6f2532dd';
}

final templateParamRegex = RegExp(r'{{(.*?)}}');
