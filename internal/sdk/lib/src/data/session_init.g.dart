// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_init.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionInitResponse _$SessionInitResponseFromJson(Map<String, dynamic> json) => SessionInitResponse(
  sessionId: json['sessionId'] as String? ?? '',
  resolvedProviderVersion: json['resolvedProviderVersion'] as String?,
);

Map<String, dynamic> _$SessionInitResponseToJson(SessionInitResponse instance) => <String, dynamic>{
  'sessionId': instance.sessionId,
  'resolvedProviderVersion': instance.resolvedProviderVersion,
};
