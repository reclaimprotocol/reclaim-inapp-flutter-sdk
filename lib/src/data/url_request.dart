import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'url_request.g.dart';

@JsonSerializable()
class ReclaimUrlRequest {
  final String
      providerId;
  final String
      applicationId;
  final String
      signature;
  final String
      timestamp;
  final String
      callbackUrl;
  final String?
      context;
  final String?
      sessionId;
  final String?
      redirectUrl;
  final String?
      verificationType;
  final bool?
      acceptAiProviders;
  final bool?
      jsonProofResponse;
  final Map<
      String,
      String>? parameters;

  const ReclaimUrlRequest({
    required this.providerId,
    required this.applicationId,
    required this.signature,
    required this.callbackUrl,
    required this.timestamp,
    this.context,
    this.sessionId,
    this.redirectUrl,
    this.verificationType,
    this.parameters,
    this.acceptAiProviders,
    this.jsonProofResponse,
  });

  factory ReclaimUrlRequest.fromJson(Map<String, dynamic> json) =>
      _$ReclaimUrlRequestFromJson(json);

  factory ReclaimUrlRequest.fromUrl(
      String
          url) {
    String
        encodedTemplate =
        url.split('template=')[1];
    String
        decodedTemplate =
        Uri.decodeComponent(encodedTemplate);
    Map<String, dynamic>
        jsonObject =
        json.decode(decodedTemplate) as Map<String, dynamic>;
    final ReclaimUrlRequest
        decodedRequest =
        ReclaimUrlRequest.fromJson(jsonObject);
    return decodedRequest;
  }

  Map<String,
          dynamic>
      toJson() =>
          _$ReclaimUrlRequestToJson(this);
}
