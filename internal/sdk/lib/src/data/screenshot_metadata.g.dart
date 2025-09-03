// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screenshot_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScreenshotMetadata _$ScreenshotMetadataFromJson(Map<String, dynamic> json) => ScreenshotMetadata(
  id: json['id'] as String,
  sessionId: json['sessionId'] as String,
  providerId: json['providerId'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
  url: json['url'] as String,
  pageTitle: json['pageTitle'] as String,
  screenshotNumber: json['screenshotNumber'] as int?,
  eventType: json['eventType'] as String?,
  additionalData: json['additionalData'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ScreenshotMetadataToJson(ScreenshotMetadata instance) => <String, dynamic>{
  'id': instance.id,
  'sessionId': instance.sessionId,
  'providerId': instance.providerId,
  'timestamp': instance.timestamp.toIso8601String(),
  'url': instance.url,
  'pageTitle': instance.pageTitle,
  'screenshotNumber': instance.screenshotNumber,
  'eventType': instance.eventType,
  'additionalData': instance.additionalData,
};
