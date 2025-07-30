import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import '../../logging/logging.dart';

part 'verification_request.g.dart';

final _logger = logging.child('verification_request');

@JsonSerializable()
@immutable
class ClientSdkVerificationRequest {
  final String? providerId;
  final String? applicationId;
  final String? signature;
  final String? timestamp;
  final String? callbackUrl;
  @JsonKey(name: 'context')
  final String? contextString;
  final String? sessionId;
  final String? redirectUrl;
  final bool? isCloseButtonVisible;
  final bool? jsonProofResponse;
  final Map<String, String>? parameters;
  final String? providerVersion;
  final String? resolvedProviderVersion;

  const ClientSdkVerificationRequest({
    required this.providerId,
    required this.applicationId,
    required this.signature,
    required this.callbackUrl,
    required this.timestamp,
    this.contextString,
    this.sessionId,
    this.redirectUrl,
    this.parameters,
    this.isCloseButtonVisible,
    this.jsonProofResponse,
    this.providerVersion,
    this.resolvedProviderVersion,
  });

  factory ClientSdkVerificationRequest.fromJson(Map<dynamic, dynamic> json) {
    return _$ClientSdkVerificationRequestFromJson(<String, dynamic>{
      for (final key in json.keys) key.toString(): json[key],
    });
  }

  factory ClientSdkVerificationRequest.fromUrl(String url) {
    final data =
        Uri.parse(url).queryParameters['template'] ??
        // The deeplink url is not always correct, so we try to fix it by replacing the /template with /?template
        Uri.parse(url.replaceFirst('/template', '/?template')).queryParameters['template'];
    if (data == null) {
      throw FormatException('No template found in url');
    }

    dynamic template;

    try {
      template = json.decode(data);
    } catch (e, s) {
      _logger.severe('Not a valid json', e, s);
      throw FormatException('Template data is not a valid json');
    }

    return ClientSdkVerificationRequest.fromJson(template);
  }

  Map<String, dynamic> toJson() {
    return _$ClientSdkVerificationRequestToJson(this);
  }
}
