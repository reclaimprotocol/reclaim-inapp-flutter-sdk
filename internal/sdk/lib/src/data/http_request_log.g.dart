// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'http_request_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RequestLog _$RequestLogFromJson(Map<String, dynamic> json) => RequestLog(
  url: json['url'] as String,
  requestBody: json['requestBody'] as String,
  responseBody: json['responseBody'] as String,
  method: json['method'] as String,
  currentPageUrl: json['currentPageUrl'] as String,
  contentType: json['contentType'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$RequestLogToJson(RequestLog instance) => <String, dynamic>{
  'url': instance.url,
  'requestBody': instance.requestBody,
  'responseBody': instance.responseBody,
  'method': instance.method,
  'currentPageUrl': instance.currentPageUrl,
  'contentType': instance.contentType,
  'metadata': instance.metadata,
};
