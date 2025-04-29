import 'package:json_annotation/json_annotation.dart';

part 'manual_verification.g.dart';

@JsonSerializable()
class RequestLog {
  final String
      url;
  final String
      requestBody;
  final String
      responseBody;
  final String
      method;
  final String
      currentPageUrl;
  final String?
      contentType;
  final Map<
      String,
      Object?>? metadata;

  const RequestLog({
    required this.url,
    required this.requestBody,
    required this.responseBody,
    required this.method,
    required this.currentPageUrl,
    required this.contentType,
    required this.metadata,
  });

  factory RequestLog.fromJson(Map<String, dynamic> json) =>
      _$RequestLogFromJson(json);

  Map<String,
          dynamic>
      toJson() =>
          _$RequestLogToJson(this);
}

@JsonSerializable()
class ManualVerificationParameter {
  final String
      key;
  final String
      value;

  ManualVerificationParameter(
      {required this.key,
      required this.value});

  factory ManualVerificationParameter.fromJson(Map<String, dynamic> json) =>
      _$ManualVerificationParameterFromJson(json);

  Map<String,
          dynamic>
      toJson() =>
          _$ManualVerificationParameterToJson(this);
}

@JsonSerializable()
class CreateManualVerificationSessionPayload {
  final String
      sessionId;
  final String
      appId;
  final String
      httpProviderId;
  final String?
      webhookUrl;
  final List<ManualVerificationParameter>
      parameters;

  CreateManualVerificationSessionPayload({
    required this.sessionId,
    required this.appId,
    required this.httpProviderId,
    required this.parameters,
    this.webhookUrl,
  });

  factory CreateManualVerificationSessionPayload.fromJson(
    Map<String, dynamic>
        json,
  ) =>
      _$CreateManualVerificationSessionPayloadFromJson(json);

  Map<String,
          dynamic>
      toJson() =>
          _$CreateManualVerificationSessionPayloadToJson(this);
}
