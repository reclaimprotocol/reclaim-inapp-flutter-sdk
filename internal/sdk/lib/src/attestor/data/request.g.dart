// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExtractHtmlElementRequest _$ExtractHtmlElementRequestFromJson(
  Map<String, dynamic> json,
) => ExtractHtmlElementRequest(
  html: json['html'] as String,
  xpathExpression: json['xpathExpression'] as String,
  contentsOnly: json['contentsOnly'] as bool,
);

Map<String, dynamic> _$ExtractHtmlElementRequestToJson(
  ExtractHtmlElementRequest instance,
) => <String, dynamic>{
  'html': instance.html,
  'xpathExpression': instance.xpathExpression,
  'contentsOnly': instance.contentsOnly,
};

ExtractJsonValueIndexRequest _$ExtractJsonValueIndexRequestFromJson(
  Map<String, dynamic> json,
) => ExtractJsonValueIndexRequest(
  jsonString: json['json'] as String,
  jsonPath: json['jsonPath'] as String,
);

Map<String, dynamic> _$ExtractJsonValueIndexRequestToJson(
  ExtractJsonValueIndexRequest instance,
) => <String, dynamic>{
  'json': instance.jsonString,
  'jsonPath': instance.jsonPath,
};

SetAttestorDebugLevelRequest _$SetAttestorDebugLevelRequestFromJson(
  Map<String, dynamic> json,
) => SetAttestorDebugLevelRequest(
  logLevel: json['logLevel'] as String,
  sendLogsToApp: json['sendLogsToApp'] as bool,
);

Map<String, dynamic> _$SetAttestorDebugLevelRequestToJson(
  SetAttestorDebugLevelRequest instance,
) => <String, dynamic>{
  'logLevel': instance.logLevel,
  'sendLogsToApp': instance.sendLogsToApp,
};
