import 'package:json_annotation/json_annotation.dart';

part 'request.g.dart';

@JsonSerializable()
class ExtractHtmlElementRequest {
  final String html;
  final String xpathExpression;
  final bool contentsOnly;

  const ExtractHtmlElementRequest({required this.html, required this.xpathExpression, required this.contentsOnly});

  factory ExtractHtmlElementRequest.fromJson(Map<String, dynamic> json) => _$ExtractHtmlElementRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ExtractHtmlElementRequestToJson(this);
}

@JsonSerializable()
class ExtractJsonValueIndexRequest {
  @JsonKey(name: 'json')
  final String jsonString;
  @JsonKey(name: 'jsonPath')
  final String jsonPath;

  const ExtractJsonValueIndexRequest({required this.jsonString, required this.jsonPath});

  factory ExtractJsonValueIndexRequest.fromJson(Map<String, dynamic> json) =>
      _$ExtractJsonValueIndexRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ExtractJsonValueIndexRequestToJson(this);
}

@JsonSerializable()
class SetAttestorDebugLevelRequest {
  final String logLevel;
  final bool sendLogsToApp;

  const SetAttestorDebugLevelRequest({required this.logLevel, required this.sendLogsToApp});

  factory SetAttestorDebugLevelRequest.fromJson(Map<String, dynamic> json) =>
      _$SetAttestorDebugLevelRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetAttestorDebugLevelRequestToJson(this);
}
