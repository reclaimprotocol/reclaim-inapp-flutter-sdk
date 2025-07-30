import 'package:reclaim_inapp_sdk/reclaim_inapp_sdk.dart';

bool _deepEquals(Object? a, Object? b) {
  if (a is List && b is List) {
    return a.length == b.length &&
        a.indexed
            .every(((int, dynamic) item) => _deepEquals(item.$2, b[item.$1]));
  }
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.entries.every((MapEntry<Object?, Object?> entry) =>
            (b as Map<Object?, Object?>).containsKey(entry.key) &&
            _deepEquals(entry.value, b[entry.key]));
  }
  return a == b;
}

class ReclaimApiVerificationResponse {
  ReclaimApiVerificationResponse({
    required this.sessionId,
    required this.didSubmitManualVerification,
    required this.proofs,
    this.exception,
  });

  String sessionId;

  bool didSubmitManualVerification;

  List<Map<String, dynamic>> proofs;

  ReclaimException? exception;

  List<Object?> _toList() {
    return <Object?>[sessionId, didSubmitManualVerification, proofs, exception];
  }

  Object encode() {
    return _toList();
  }

  static ReclaimApiVerificationResponse decode(Object result) {
    result as List<Object?>;
    return ReclaimApiVerificationResponse(
      sessionId: result[0]! as String,
      didSubmitManualVerification: result[1]! as bool,
      proofs: (result[2] as List<Object?>?)!.cast<Map<String, dynamic>>(),
      exception: result[3] as ReclaimException?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'didSubmitManualVerification': didSubmitManualVerification,
      'proofs': proofs,
      'exception': exception?.toString(),
    };
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (other is! ReclaimApiVerificationResponse ||
        other.runtimeType != runtimeType) {
      return false;
    }
    if (identical(this, other)) {
      return true;
    }
    return _deepEquals(encode(), other.encode());
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => Object.hashAll(_toList());
}

class ClientProviderInformationOverride {
  ClientProviderInformationOverride({
    this.providerInformationUrl,
    this.providerInformationJsonString,
    this.canFetchProviderInformationFromHost = false,
  });

  String? providerInformationUrl;

  String? providerInformationJsonString;

  bool canFetchProviderInformationFromHost;

  List<Object?> _toList() {
    return <Object?>[
      providerInformationUrl,
      providerInformationJsonString,
      canFetchProviderInformationFromHost
    ];
  }

  Object encode() {
    return _toList();
  }

  static ClientProviderInformationOverride decode(Object result) {
    result as List<Object?>;
    return ClientProviderInformationOverride(
      providerInformationUrl: result[0] as String?,
      providerInformationJsonString: result[1] as String?,
      canFetchProviderInformationFromHost: result[2]! as bool,
    );
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (other is! ClientProviderInformationOverride ||
        other.runtimeType != runtimeType) {
      return false;
    }
    if (identical(this, other)) {
      return true;
    }
    return _deepEquals(encode(), other.encode());
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => Object.hashAll(_toList());
}

class ClientFeatureOverrides {
  ClientFeatureOverrides({
    this.cookiePersist,
    this.singleReclaimRequest,
    this.idleTimeThresholdForManualVerificationTrigger,
    this.sessionTimeoutForManualVerificationTrigger,
    this.attestorBrowserRpcUrl,
    this.isAIFlowEnabled,
    this.manualReviewMessage,
    this.loginPromptMessage,
  });

  bool? cookiePersist;

  bool? singleReclaimRequest;

  int? idleTimeThresholdForManualVerificationTrigger;

  int? sessionTimeoutForManualVerificationTrigger;

  String? attestorBrowserRpcUrl;

  bool? isAIFlowEnabled;

  String? manualReviewMessage;

  String? loginPromptMessage;

  List<Object?> _toList() {
    return <Object?>[
      cookiePersist,
      singleReclaimRequest,
      idleTimeThresholdForManualVerificationTrigger,
      sessionTimeoutForManualVerificationTrigger,
      attestorBrowserRpcUrl,
      isAIFlowEnabled,
      manualReviewMessage,
      loginPromptMessage,
    ];
  }

  Object encode() {
    return _toList();
  }

  static ClientFeatureOverrides decode(Object result) {
    result as List<Object?>;
    return ClientFeatureOverrides(
      cookiePersist: result[0] as bool?,
      singleReclaimRequest: result[1] as bool?,
      idleTimeThresholdForManualVerificationTrigger: result[2] as int?,
      sessionTimeoutForManualVerificationTrigger: result[3] as int?,
      attestorBrowserRpcUrl: result[4] as String?,
      isAIFlowEnabled: result[5] as bool?,
      manualReviewMessage: result[6] as String?,
      loginPromptMessage: result[7] as String?,
    );
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (other is! ClientFeatureOverrides || other.runtimeType != runtimeType) {
      return false;
    }
    if (identical(this, other)) {
      return true;
    }
    return _deepEquals(encode(), other.encode());
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => Object.hashAll(_toList());
}

class ClientLogConsumerOverride {
  ClientLogConsumerOverride({
    this.enableLogHandler = true,
    this.canSdkCollectTelemetry = true,
    this.canSdkPrintLogs = false,
  });

  bool enableLogHandler;

  bool canSdkCollectTelemetry;

  bool? canSdkPrintLogs;

  List<Object?> _toList() {
    return <Object?>[enableLogHandler, canSdkCollectTelemetry, canSdkPrintLogs];
  }

  Object encode() {
    return _toList();
  }

  static ClientLogConsumerOverride decode(Object result) {
    result as List<Object?>;
    return ClientLogConsumerOverride(
      enableLogHandler: result[0]! as bool,
      canSdkCollectTelemetry: result[1]! as bool,
      canSdkPrintLogs: result[2] as bool?,
    );
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (other is! ClientLogConsumerOverride ||
        other.runtimeType != runtimeType) {
      return false;
    }
    if (identical(this, other)) {
      return true;
    }
    return _deepEquals(encode(), other.encode());
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => Object.hashAll(_toList());
}

class ClientReclaimSessionManagementOverride {
  ClientReclaimSessionManagementOverride(
      {this.enableSdkSessionManagement = true});

  bool enableSdkSessionManagement;

  List<Object?> _toList() {
    return <Object?>[enableSdkSessionManagement];
  }

  Object encode() {
    return _toList();
  }

  static ClientReclaimSessionManagementOverride decode(Object result) {
    result as List<Object?>;
    return ClientReclaimSessionManagementOverride(
        enableSdkSessionManagement: result[0]! as bool);
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (other is! ClientReclaimSessionManagementOverride ||
        other.runtimeType != runtimeType) {
      return false;
    }
    if (identical(this, other)) {
      return true;
    }
    return _deepEquals(encode(), other.encode());
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => Object.hashAll(_toList());
}

class ClientReclaimAppInfoOverride {
  ClientReclaimAppInfoOverride(
      {required this.appName,
      required this.appImageUrl,
      required this.isRecurring});

  String appName;

  String appImageUrl;

  bool isRecurring;

  List<Object?> _toList() {
    return <Object?>[appName, appImageUrl, isRecurring];
  }

  Object encode() {
    return _toList();
  }

  static ClientReclaimAppInfoOverride decode(Object result) {
    result as List<Object?>;
    return ClientReclaimAppInfoOverride(
      appName: result[0]! as String,
      appImageUrl: result[1]! as String,
      isRecurring: result[2]! as bool,
    );
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (other is! ClientReclaimAppInfoOverride ||
        other.runtimeType != runtimeType) {
      return false;
    }
    if (identical(this, other)) {
      return true;
    }
    return _deepEquals(encode(), other.encode());
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => Object.hashAll(_toList());
}

/// Identification information of a session.
class ReclaimSessionIdentityUpdate {
  ReclaimSessionIdentityUpdate(
      {required this.appId, required this.providerId, required this.sessionId});

  /// The application id.
  String appId;

  /// The provider id.
  String providerId;

  /// The session id.
  String sessionId;

  List<Object?> _toList() {
    return <Object?>[appId, providerId, sessionId];
  }

  Object encode() {
    return _toList();
  }

  static ReclaimSessionIdentityUpdate decode(Object result) {
    result as List<Object?>;
    return ReclaimSessionIdentityUpdate(
      appId: result[0]! as String,
      providerId: result[1]! as String,
      sessionId: result[2]! as String,
    );
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (other is! ReclaimSessionIdentityUpdate ||
        other.runtimeType != runtimeType) {
      return false;
    }
    if (identical(this, other)) {
      return true;
    }
    return _deepEquals(encode(), other.encode());
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => Object.hashAll(_toList());
}

/// Apis implemented by the host using the Reclaim module.
abstract class ReclaimHostOverridesApi {
  Future<SessionInitResponse> createSession({
    required String appId,
    required String providerId,
    required String timestamp,
    required String signature,
    required String providerVersion,
  });

  Future<String> fetchProviderInformation({
    required String appId,
    required String providerId,
    required String sessionId,
    required String signature,
    required String timestamp,
  });

  Future<void> logSession({
    required String appId,
    required String providerId,
    required String sessionId,
    required String logType,
    Map<String, dynamic>? metadata,
  });

  Future<void> onLogs(String logJsonString);

  Future<void> onSessionIdentityUpdate(ReclaimSessionIdentityUpdate? update);

  Future<bool> updateSession(
      {required String sessionId, required SessionStatus status});
}
