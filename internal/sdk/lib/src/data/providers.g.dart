// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReclaimDataProvidersResponse _$ReclaimDataProvidersResponseFromJson(Map<String, dynamic> json) =>
    ReclaimDataProvidersResponse(
      messsage: json['messsage'] as String?,
      isSucces: json['isSucces'] as bool?,
      providers:
          json['providers'] == null ? null : ReclaimDataProviders.fromJson(json['providers'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ReclaimDataProvidersResponseToJson(ReclaimDataProvidersResponse instance) => <String, dynamic>{
  'messsage': instance.messsage,
  'isSucces': instance.isSucces,
  'providers': instance.providers,
};

ReclaimDataProviders _$ReclaimDataProvidersFromJson(Map<String, dynamic> json) => ReclaimDataProviders(
  appId: json['appId'] as String?,
  httpProvider:
      (json['httpProvider'] as List<dynamic>?)?.map((e) => HttpProvider.fromJson(e as Map<String, dynamic>)).toList(),
);

Map<String, dynamic> _$ReclaimDataProvidersToJson(ReclaimDataProviders instance) => <String, dynamic>{
  'appId': instance.appId,
  'httpProvider': instance.httpProvider,
};

HttpProvider _$HttpProviderFromJson(Map<String, dynamic> json) => HttpProvider(
  name: json['name'] as String?,
  description: json['description'] as String?,
  logoUrl: json['logoUrl'] as String,
  providerType: $enumDecodeNullable(_$ProviderTypeEnumMap, json['providerType']),
  loginUrl: json['loginUrl'] as String?,
  isActive: json['isActive'] as bool?,
  customInjection: json['customInjection'] as String?,
  userAgent: json['userAgent'] == null ? null : UserAgentSettings.fromJson(json['userAgent'] as Map<String, dynamic>),
  isApproved: json['isApproved'] as bool?,
  geoLocation: json['geoLocation'] as String?,
  isVerified: json['isVerified'] as bool?,
  injectionType: $enumDecodeNullable(_$InjectionTypeEnumMap, json['injectionType']),
  disableRequestReplay: json['disableRequestReplay'] as bool?,
  providerHash: json['providerHash'] as String?,
  additionalClientOptions: json['additionalClientOptions'] as Map<String, dynamic>?,
  verificationType: json['verificationType'] as String?,
  pageTitle: json['pageTitle'] as String?,
  requestData:
      (json['requestData'] as List<dynamic>?)
          ?.map((e) => DataProviderRequest.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  useIncognitoWebview: json['useIncognitoWebview'] as bool? ?? false,
);

Map<String, dynamic> _$HttpProviderToJson(HttpProvider instance) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'logoUrl': instance.logoUrl,
  'providerType': _$ProviderTypeEnumMap[instance.providerType],
  'loginUrl': instance.loginUrl,
  'isActive': instance.isActive,
  'customInjection': instance.customInjection,
  'userAgent': instance.userAgent,
  'isApproved': instance.isApproved,
  'geoLocation': instance.geoLocation,
  'isVerified': instance.isVerified,
  'injectionType': _$InjectionTypeEnumMap[instance.injectionType],
  'disableRequestReplay': instance.disableRequestReplay,
  'providerHash': instance.providerHash,
  'additionalClientOptions': instance.additionalClientOptions,
  'verificationType': instance.verificationType,
  'pageTitle': instance.pageTitle,
  'requestData': instance.requestData,
  'useIncognitoWebview': instance.useIncognitoWebview,
};

const _$ProviderTypeEnumMap = {ProviderType.PRIVATE: 'PRIVATE', ProviderType.PUBLIC: 'PUBLIC'};

const _$InjectionTypeEnumMap = {InjectionType.MSWJS: 'MSWJS', InjectionType.NONE: 'NONE', InjectionType.XHOOK: 'XHOOK'};

BodySniff _$BodySniffFromJson(Map<String, dynamic> json) =>
    BodySniff(enabled: json['enabled'] as bool?, template: json['template'] as String?);

Map<String, dynamic> _$BodySniffToJson(BodySniff instance) => <String, dynamic>{
  'enabled': instance.enabled,
  'template': instance.template,
};

DataProviderRequest _$DataProviderRequestFromJson(Map<String, dynamic> json) => DataProviderRequest(
  url: json['url'] as String?,
  urlType: $enumDecodeNullable(_$UrlTypeEnumMap, json['urlType']),
  method: $enumDecodeNullable(_$RequestMethodTypeEnumMap, json['method']),
  responseMatches:
      (json['responseMatches'] as List<dynamic>?)
          ?.map((e) => ResponseMatch.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  responseRedactions:
      (json['responseRedactions'] as List<dynamic>?)
          ?.map((e) => ResponseRedaction.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  bodySniff: json['bodySniff'] == null ? null : BodySniff.fromJson(json['bodySniff'] as Map<String, dynamic>),
  requestHash: json['requestHash'] as String?,
  expectedPageUrl: json['expectedPageUrl'] as String?,
);

Map<String, dynamic> _$DataProviderRequestToJson(DataProviderRequest instance) => <String, dynamic>{
  'url': instance.url,
  'urlType': _$UrlTypeEnumMap[instance.urlType],
  'method': _$RequestMethodTypeEnumMap[instance.method],
  'responseMatches': instance.responseMatches,
  'responseRedactions': instance.responseRedactions,
  'bodySniff': instance.bodySniff,
  'requestHash': instance.requestHash,
  'expectedPageUrl': instance.expectedPageUrl,
};

const _$UrlTypeEnumMap = {UrlType.REGEX: 'REGEX', UrlType.CONSTANT: 'CONSTANT', UrlType.TEMPLATE: 'TEMPLATE'};

const _$RequestMethodTypeEnumMap = {RequestMethodType.GET: 'GET', RequestMethodType.POST: 'POST'};

ResponseMatch _$ResponseMatchFromJson(Map<String, dynamic> json) => ResponseMatch(
  value: json['value'] as String?,
  type: json['type'] as String?,
  invert: json['invert'] as bool? ?? false,
  description: json['description'] as String?,
  order: json['order'] as num?,
);

Map<String, dynamic> _$ResponseMatchToJson(ResponseMatch instance) => <String, dynamic>{
  'value': instance.value,
  'type': instance.type,
  'invert': instance.invert,
};

ResponseRedaction _$ResponseRedactionFromJson(Map<String, dynamic> json) => ResponseRedaction(
  xPath: json['xPath'] as String?,
  jsonPath: json['jsonPath'] as String?,
  regex: json['regex'] as String?,
  matchType: $enumDecodeNullable(_$MatchTypeEnumMap, json['matchType']),
  hash: _fromJsonWhenNotEmpty(json['hash']),
);

Map<String, dynamic> _$ResponseRedactionToJson(ResponseRedaction instance) => <String, dynamic>{
  'xPath': instance.xPath,
  'jsonPath': instance.jsonPath,
  'regex': instance.regex,
  if (instance.hash case final value?) 'hash': value,
};

const _$MatchTypeEnumMap = {MatchType.GREEDY: 'greedy', MatchType.LAZY: 'lazy'};

UserAgentSettings _$UserAgentSettingsFromJson(Map<String, dynamic> json) =>
    UserAgentSettings(ios: json['ios'] as String?, android: json['android'] as String?);

Map<String, dynamic> _$UserAgentSettingsToJson(UserAgentSettings instance) => <String, dynamic>{
  'ios': instance.ios,
  'android': instance.android,
};
