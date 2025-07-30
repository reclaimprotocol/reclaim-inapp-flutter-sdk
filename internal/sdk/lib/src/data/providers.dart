import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:web3dart/crypto.dart';

import '../utils/list.dart';

part 'providers.g.dart';

@JsonSerializable()
class ReclaimDataProvidersResponse {
  @JsonKey(name: "messsage")
  final String? messsage;
  @JsonKey(name: "isSucces")
  final bool? isSucces;
  @JsonKey(name: "providers")
  final ReclaimDataProviders? providers;

  ReclaimDataProvidersResponse({this.messsage, this.isSucces, this.providers});

  factory ReclaimDataProvidersResponse.fromJson(Map<String, dynamic> json) =>
      _$ReclaimDataProvidersResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ReclaimDataProvidersResponseToJson(this);
}

enum InjectionType {
  @JsonValue('MSWJS')
  MSWJS,
  @JsonValue('HAWKEYE')
  HAWKEYE,
  @JsonValue('NONE')
  NONE,
  @JsonValue('XHOOK')
  XHOOK;

  factory InjectionType.fromString(String value) {
    return switch (value.toLowerCase().trim()) {
      'mswjs' => InjectionType.MSWJS,
      'none' => InjectionType.NONE,
      'hawkeye' => InjectionType.HAWKEYE,
      'xhook' => InjectionType.XHOOK,
      _ => throw Exception('Invalid injection type: $value'),
    };
  }
}

@JsonSerializable()
class ReclaimDataProviders {
  @JsonKey(name: "appId")
  final String? appId;
  @JsonKey(name: "httpProvider")
  final List<HttpProvider>? httpProvider;

  ReclaimDataProviders({this.appId, this.httpProvider});

  factory ReclaimDataProviders.fromJson(Map<String, dynamic> json) => _$ReclaimDataProvidersFromJson(json);

  Map<String, dynamic> toJson() => _$ReclaimDataProvidersToJson(this);
}

@JsonSerializable()
class HttpProvider {
  @JsonKey(name: "name")
  final String? name;
  @JsonKey(name: "description")
  final String? description;
  @JsonKey(name: "logoUrl")
  final String logoUrl;
  @JsonKey(name: "providerType")
  final ProviderType? providerType;
  @JsonKey(name: "loginUrl")
  final String? loginUrl;
  @JsonKey(name: "isActive")
  final bool? isActive;
  @JsonKey(name: "customInjection")
  final String? customInjection;
  @JsonKey(name: "userAgent")
  final UserAgentSettings? userAgent;
  @JsonKey(name: "isApproved")
  final bool? isApproved;
  @JsonKey(name: "geoLocation")
  final String? geoLocation;
  @JsonKey(name: "isVerified")
  final bool? isVerified;
  @JsonKey(name: "injectionType")
  final InjectionType? injectionType;
  @JsonKey(name: "disableRequestReplay")
  final bool? disableRequestReplay;
  @JsonKey(name: "providerHash")
  final String? providerHash;
  @JsonKey(name: "additionalClientOptions")
  final Map<String, dynamic>? additionalClientOptions;
  @JsonKey(name: "verificationType")
  final String? verificationType;
  @JsonKey(name: "pageTitle")
  final String? pageTitle;
  @JsonKey(name: "requestData", defaultValue: [])
  final List<DataProviderRequest> requestData;
  @JsonKey(name: "useIncognitoWebview", defaultValue: false)
  final bool useIncognitoWebview;
  @JsonKey(name: "version")
  final Object? version;

  const HttpProvider({
    this.name,
    this.description,
    required this.logoUrl,
    this.providerType,
    this.loginUrl,
    this.isActive,
    this.customInjection,
    this.userAgent,
    this.isApproved,
    this.geoLocation,
    this.isVerified,
    this.injectionType,
    this.disableRequestReplay,
    this.providerHash,
    this.additionalClientOptions,
    this.verificationType,
    this.pageTitle,
    this.version,
    required this.requestData,
    required this.useIncognitoWebview,
  });

  factory HttpProvider.fromJson(Map<String, dynamic> json) => _$HttpProviderFromJson(json);

  Map<String, dynamic> toJson() => _$HttpProviderToJson(this);

  bool isAIProvider() {
    return verificationType == 'AI';
  }
}

enum UrlType { REGEX, CONSTANT, TEMPLATE }

enum RequestMethodType {
  GET,
  POST;

  factory RequestMethodType.fromString(String value) {
    return switch (value.toLowerCase().trim()) {
      'get' => RequestMethodType.GET,
      'post' => RequestMethodType.POST,
      _ => throw Exception('Invalid request method type: $value'),
    };
  }
}

enum ProviderType { PRIVATE, PUBLIC }

enum MatchType {
  @JsonValue('greedy')
  GREEDY,
  @JsonValue('lazy')
  LAZY,
}

@JsonSerializable()
class BodySniff {
  @JsonKey(name: "enabled")
  final bool? enabled;
  @JsonKey(name: "template")
  final String? template;

  BodySniff({this.enabled, this.template});

  factory BodySniff.fromJson(Map<String, dynamic> json) => _$BodySniffFromJson(json);

  Map<String, dynamic> toJson() => _$BodySniffToJson(this);
}

/// Refer: https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch#including_credentials
enum WebCredentialsType {
  @JsonValue('omit')
  OMIT,
  @JsonValue('same-origin')
  SAME_ORIGIN,
  @JsonValue('include')
  INCLUDE;

  factory WebCredentialsType.fromString(String? value) {
    return switch (value?.toLowerCase().trim()) {
      'omit' => WebCredentialsType.OMIT,
      'same-origin' || 'same_origin' => WebCredentialsType.SAME_ORIGIN,
      null || 'include' || '' => WebCredentialsType.INCLUDE,
      _ => throw ArgumentError.value(value, 'value', 'Invalid web credentials type'),
    };
  }
}

@JsonSerializable()
class DataProviderRequest {
  @JsonKey(name: "url")
  final String? url;
  @JsonKey(name: "urlType")
  final UrlType? urlType;
  @JsonKey(name: "method")
  final RequestMethodType? method;
  @JsonKey(name: "responseMatches", defaultValue: [])
  final List<ResponseMatch> responseMatches;
  @JsonKey(name: "responseRedactions", defaultValue: [])
  final List<ResponseRedaction> responseRedactions;
  @JsonKey(name: "bodySniff")
  final BodySniff? bodySniff;
  @JsonKey(name: "credentials", defaultValue: WebCredentialsType.INCLUDE, fromJson: WebCredentialsType.fromString)
  final WebCredentialsType credentials;
  @JsonKey(name: "requestHash")
  final String? requestHash;

  /// On which page this provider request is expected to be found
  @JsonKey(name: "expectedPageUrl")
  final String? expectedPageUrl;

  DataProviderRequest({
    this.url,
    this.urlType,
    this.method,
    required this.responseMatches,
    required this.responseRedactions,
    this.bodySniff,
    this.requestHash,
    this.expectedPageUrl,
    required this.credentials,
  });

  Set<String> getParameterNames() {
    final matches = responseMatches;
    final redactions = responseRedactions;

    final length = math.max(matches.length, redactions.length);
    if (length == 0) return const {};

    final allParameterNames = <String>{};

    for (int i = 0; i < length; i++) {
      final redaction = maybeGetAtIndex(redactions, i);
      final match = maybeGetAtIndex(matches, i);

      // prefer template param name from match if it exists over redaction.

      if (match != null) {
        final templateParamName = match.getTemplateParameterName();
        if (templateParamName != null) {
          allParameterNames.add(templateParamName);
          continue;
        }
      }

      if (redaction != null) {
        final templateParamName = redaction.getTemplateParameterName();
        if (templateParamName != null) {
          allParameterNames.add(templateParamName);
          continue;
        }
      }
    }

    return allParameterNames;
  }

  ResponseSelection? getResponseSelectionByParameterName(String param) {
    final matches = responseMatches;
    final redactions = responseRedactions;

    final length = math.max(matches.length, redactions.length);
    if (length == 0) return null;

    for (int i = 0; i < length; i++) {
      final redaction = maybeGetAtIndex(redactions, i);
      final match = maybeGetAtIndex(matches, i);

      // prefer template param name from match if it exists over redaction.

      if (match != null) {
        final templateParamName = match.getTemplateParameterName();
        if (templateParamName == param) {
          return (match: match, redaction: redaction);
        }
      }

      if (redaction != null) {
        final templateParamName = redaction.getTemplateParameterName();
        if (templateParamName == param) {
          return (match: match, redaction: redaction);
        }
      }
    }

    return null;
  }

  DataProviderRequest copyWith({
    String? url,
    UrlType? urlType,
    RequestMethodType? method,
    List<ResponseMatch>? responseMatches,
    List<ResponseRedaction>? responseRedactions,
    BodySniff? bodySniff,
    String? requestHash,
    String? expectedPageUrl,
    WebCredentialsType? credentials,
  }) {
    return DataProviderRequest(
      url: url ?? this.url,
      urlType: urlType ?? this.urlType,
      method: method ?? this.method,
      responseMatches: responseMatches ?? this.responseMatches,
      responseRedactions: responseRedactions ?? this.responseRedactions,
      bodySniff: bodySniff ?? this.bodySniff,
      requestHash: requestHash ?? this.requestHash,
      expectedPageUrl: expectedPageUrl ?? this.expectedPageUrl,
      credentials: credentials ?? this.credentials,
    );
  }

  factory DataProviderRequest.fromJson(Map<String, dynamic> json) => _$DataProviderRequestFromJson(json);

  factory DataProviderRequest.fromScriptInvocation(Map<String, dynamic> json) {
    final request = DataProviderRequest.fromJson(json);
    return request.copyWith(
      urlType: () {
        if (request.urlType != null) {
          return request.urlType;
        }
        if (request.url?.contains('{{') == true) {
          return UrlType.TEMPLATE;
        }
        return UrlType.CONSTANT;
      }(),
    );
  }

  Map<String, dynamic> toJson() {
    return SplayTreeMap.from(_$DataProviderRequestToJson(this));
  }

  @visibleForTesting
  String get requestIdentifierParams {
    // matches with the devtool generated hash
    final orderedProviderParams = SplayTreeMap.from({
      'url': url,
      'method': method?.name,
      'responseRedactions': responseRedactions,
      'responseMatches': responseMatches,
      'reqBody': bodySniff?.enabled == true ? (bodySniff?.template ?? "") : "",
    });
    final canoncalizedJsonString = json.encode(orderedProviderParams);
    return canoncalizedJsonString;
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  late final String requestIdentifier = () {
    final canoncalizedJsonString = requestIdentifierParams;
    final data = utf8.encode(canoncalizedJsonString);
    final keccakHash = keccak256(data);

    return '0x${keccakHash.map((byte) {
      return byte.toRadixString(16).padLeft(2, '0');
    }).join()}';
  }();
}

typedef ResponseSelection = ({ResponseMatch? match, ResponseRedaction? redaction});

@JsonSerializable()
class ResponseMatch {
  @JsonKey(name: "value")
  final String? value;
  @JsonKey(name: "type")
  final String? type;
  @JsonKey(name: "invert", defaultValue: false)
  final bool invert;
  @JsonKey(name: "description", includeToJson: false)
  final String? description;
  @JsonKey(name: 'order', includeToJson: false)
  final num? order;

  const ResponseMatch({this.value, this.type, required this.invert, this.description, this.order});

  static final _matchParamRegex = RegExp(r'{{(.*?)}}');

  String? getTemplateParameterName() {
    final matchValue = value;
    if (matchValue == null || matchValue.isEmpty) return null;

    final matchRegexMatch = _matchParamRegex.firstMatch(matchValue);
    final matchingKey = matchRegexMatch?.group(1);
    if (matchingKey == null || matchingKey.isEmpty) return null;

    return matchingKey;
  }

  factory ResponseMatch.fromJson(Map<String, dynamic> json) => _$ResponseMatchFromJson(json);

  Map<String, dynamic> toJson() => SplayTreeMap.from(_$ResponseMatchToJson(this));
}

@JsonSerializable()
class ResponseRedaction {
  @JsonKey(name: "xPath")
  final String? xPath;
  @JsonKey(name: "jsonPath")
  final String? jsonPath;
  @JsonKey(name: "regex")
  final String? regex;

  @JsonKey(
    name: "matchType",
    // Not including in toJson because we don't need to send it to the attestor
    // This parameter is not in the protocol
    includeToJson: false,
  )
  final MatchType? matchType;
  @JsonKey(name: "hash", includeIfNull: false, fromJson: _fromJsonWhenNotEmpty)
  final String? hash;

  static final _namedParamRegex = RegExp(r'\?\<(.*?)\>');

  String? getTemplateParameterName() {
    final redactionRegex = regex;
    if (redactionRegex == null || redactionRegex.isEmpty) return null;

    final redactionRegexMatch = _namedParamRegex.firstMatch(redactionRegex);
    final matchingKey = redactionRegexMatch?.group(1);
    if (matchingKey == null || matchingKey.isEmpty) return null;

    return matchingKey;
  }

  const ResponseRedaction({this.xPath, this.jsonPath, this.regex, required this.matchType, this.hash});

  bool get markedForHashing => hash?.trim().isNotEmpty == true;

  factory ResponseRedaction.fromJson(Map<String, dynamic> json) => _$ResponseRedactionFromJson(json);

  Map<String, dynamic> toJson() => SplayTreeMap.from(_$ResponseRedactionToJson(this));
}

String? _fromJsonWhenNotEmpty(Object? value) {
  return value is String && value.trim().isNotEmpty ? value : null;
}

@JsonSerializable()
class UserAgentSettings {
  @JsonKey(name: "ios")
  final String? ios;
  @JsonKey(name: "android")
  final String? android;

  UserAgentSettings({this.ios, this.android});

  factory UserAgentSettings.fromJson(Map<String, dynamic> json) => _$UserAgentSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$UserAgentSettingsToJson(this);
}
