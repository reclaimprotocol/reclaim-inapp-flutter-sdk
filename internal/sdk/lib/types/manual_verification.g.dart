// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_verification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RequestLog _$RequestLogFromJson(Map<String, dynamic> json) => RequestLog(
  url: json['url'] as String?,
  requestBody: json['requestBody'] as String?,
  responseBody: json['responseBody'] as String?,
  method: json['method'] as String?,
  currentPageUrl: json['currentPageUrl'] as String?,
  contentType: json['contentType'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$RequestLogToJson(RequestLog instance) =>
    <String, dynamic>{
      'url': instance.url,
      'requestBody': instance.requestBody,
      'responseBody': instance.responseBody,
      'method': instance.method,
      'currentPageUrl': instance.currentPageUrl,
      'contentType': instance.contentType,
      'metadata': instance.metadata,
    };

ManualVerificationParameter _$ManualVerificationParameterFromJson(
  Map<String, dynamic> json,
) => ManualVerificationParameter(
  key: json['key'] as String,
  value: json['value'] as String,
);

Map<String, dynamic> _$ManualVerificationParameterToJson(
  ManualVerificationParameter instance,
) => <String, dynamic>{'key': instance.key, 'value': instance.value};

CreateManualVerificationSessionPayload
_$CreateManualVerificationSessionPayloadFromJson(Map<String, dynamic> json) =>
    CreateManualVerificationSessionPayload(
      sessionId: json['sessionId'] as String,
      appId: json['appId'] as String,
      httpProviderId: json['httpProviderId'] as String,
      parameters:
          (json['parameters'] as List<dynamic>)
              .map(
                (e) => ManualVerificationParameter.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
      webhookUrl: json['webhookUrl'] as String?,
    );

Map<String, dynamic> _$CreateManualVerificationSessionPayloadToJson(
  CreateManualVerificationSessionPayload instance,
) => <String, dynamic>{
  'sessionId': instance.sessionId,
  'appId': instance.appId,
  'httpProviderId': instance.httpProviderId,
  'webhookUrl': instance.webhookUrl,
  'parameters': instance.parameters,
};
