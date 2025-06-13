import 'package:json_annotation/json_annotation.dart';

part 'http_request_log.g.dart';

@JsonSerializable()
class RequestLog {
  final String url;
  final String requestBody;
  final String responseBody;
  final String method;
  final String currentPageUrl;
  final String? contentType;
  final Map<String, Object?>? metadata;

  const RequestLog({
    required this.url,
    required this.requestBody,
    required this.responseBody,
    required this.method,
    required this.currentPageUrl,
    required this.contentType,
    required this.metadata,
  });

  factory RequestLog.fromJson(Map<String, dynamic> json) => _$RequestLogFromJson(json);

  Map<String, dynamic> toJson() => _$RequestLogToJson(this);
}
