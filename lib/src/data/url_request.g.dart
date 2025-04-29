// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'url_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReclaimUrlRequest
    _$ReclaimUrlRequestFromJson(Map<String, dynamic> json) =>
        ReclaimUrlRequest(
          providerId: json['providerId'] as String,
          applicationId: json['applicationId'] as String,
          signature: json['signature'] as String,
          callbackUrl: json['callbackUrl'] as String,
          timestamp: json['timestamp'] as String,
          context: json['context'] as String?,
          sessionId: json['sessionId'] as String?,
          redirectUrl: json['redirectUrl'] as String?,
          verificationType: json['verificationType'] as String?,
          parameters: (json['parameters'] as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, e as String)),
          acceptAiProviders: json['acceptAiProviders'] as bool?,
          jsonProofResponse: json['jsonProofResponse'] as bool?,
        );

Map<String,
    dynamic> _$ReclaimUrlRequestToJson(
        ReclaimUrlRequest
            instance) =>
    <String,
        dynamic>{
      'providerId':
          instance.providerId,
      'applicationId':
          instance.applicationId,
      'signature':
          instance.signature,
      'timestamp':
          instance.timestamp,
      'callbackUrl':
          instance.callbackUrl,
      'context':
          instance.context,
      'sessionId':
          instance.sessionId,
      'redirectUrl':
          instance.redirectUrl,
      'verificationType':
          instance.verificationType,
      'acceptAiProviders':
          instance.acceptAiProviders,
      'jsonProofResponse':
          instance.jsonProofResponse,
      'parameters':
          instance.parameters,
    };
