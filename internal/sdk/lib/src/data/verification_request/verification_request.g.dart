// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClientSdkVerificationRequest _$ClientSdkVerificationRequestFromJson(Map<String, dynamic> json) =>
    ClientSdkVerificationRequest(
      providerId: json['providerId'] as String?,
      applicationId: json['applicationId'] as String?,
      signature: json['signature'] as String?,
      callbackUrl: json['callbackUrl'] as String?,
      timestamp: json['timestamp'] as String?,
      contextString: json['context'] as String?,
      sessionId: json['sessionId'] as String?,
      redirectUrl: json['redirectUrl'] as String?,
      parameters: (json['parameters'] as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, e as String)),
      isCloseButtonVisible: json['isCloseButtonVisible'] as bool?,
      jsonProofResponse: json['jsonProofResponse'] as bool?,
      providerVersion: json['providerVersion'] as String?,
      resolvedProviderVersion: json['resolvedProviderVersion'] as String?,
    );

Map<String, dynamic> _$ClientSdkVerificationRequestToJson(ClientSdkVerificationRequest instance) => <String, dynamic>{
  'providerId': instance.providerId,
  'applicationId': instance.applicationId,
  'signature': instance.signature,
  'timestamp': instance.timestamp,
  'callbackUrl': instance.callbackUrl,
  'context': instance.contextString,
  'sessionId': instance.sessionId,
  'redirectUrl': instance.redirectUrl,
  'isCloseButtonVisible': instance.isCloseButtonVisible,
  'jsonProofResponse': instance.jsonProofResponse,
  'parameters': instance.parameters,
  'providerVersion': instance.providerVersion,
  'resolvedProviderVersion': instance.resolvedProviderVersion,
};
