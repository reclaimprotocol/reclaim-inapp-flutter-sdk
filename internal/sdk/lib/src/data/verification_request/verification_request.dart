import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import '../../logging/logging.dart';
import '../../utils/link.dart';

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

  ClientSdkVerificationRequest copyWith({
    String? callbackUrl,
    String? contextString,
    String? redirectUrl,
    Map<String, String>? parameters,
    bool? isCloseButtonVisible,
    bool? jsonProofResponse,
    String? providerVersion,
    String? resolvedProviderVersion,
  }) {
    return ClientSdkVerificationRequest(
      providerId: providerId,
      applicationId: applicationId,
      signature: signature,
      callbackUrl: callbackUrl ?? this.callbackUrl,
      timestamp: timestamp,
      contextString: contextString ?? this.contextString,
      sessionId: sessionId,
      redirectUrl: redirectUrl ?? this.redirectUrl,
      parameters: parameters ?? this.parameters,
      isCloseButtonVisible: isCloseButtonVisible ?? this.isCloseButtonVisible,
      jsonProofResponse: jsonProofResponse ?? this.jsonProofResponse,
      providerVersion: providerVersion ?? this.providerVersion,
      resolvedProviderVersion: resolvedProviderVersion ?? this.resolvedProviderVersion,
    );
  }

  factory ClientSdkVerificationRequest.fromJson(Map<dynamic, dynamic> json) {
    return _$ClientSdkVerificationRequestFromJson(<String, dynamic>{
      for (final key in json.keys) key.toString(): json[key],
    });
  }

  static Map<dynamic, dynamic> parseTemplateFromUrl(String url) {
    final data =
        Uri.parse(url).queryParameters['template'] ??
        // The deeplink url is not always correct, so we try to fix it by replacing the /template with /?template
        Uri.parse(url.replaceFirst('/template', '/?template')).queryParameters['template'];
    if (data == null) {
      throw const FormatException('No template found in url');
    }

    dynamic template;

    try {
      template = json.decode(data);
    } catch (e, s) {
      _logger.severe('Not a valid json', e, s);
      throw const FormatException('Template data is not a valid json');
    }

    if (template is! Map) {
      _logger.severe('Not a valid json map');
      throw const FormatException('Template data is not a valid json map');
    }

    if (template.isEmpty) {
      _logger.severe('Template is empty');
      throw const FormatException('Template is empty');
    }

    return template;
  }

  static Future<ClientSdkVerificationRequest> fromUrl(
    String url, {
    bool followRedirects = true,
    http.Client? client,
    int followDepth = 0,
  }) async {
    try {
      final template = parseTemplateFromUrl(url);
      return ClientSdkVerificationRequest.fromJson(template);
    } on FormatException {
      if (!followRedirects) {
        rethrow;
      }

      final location = await followUrlRedirects(url, followDepth, client: client);
      if (location == null) {
        rethrow;
      }

      return fromUrl(location, followRedirects: followRedirects, client: client, followDepth: followDepth + 1);
    }
  }

  Map<String, dynamic> toJson() {
    return _$ClientSdkVerificationRequestToJson(this);
  }
}
