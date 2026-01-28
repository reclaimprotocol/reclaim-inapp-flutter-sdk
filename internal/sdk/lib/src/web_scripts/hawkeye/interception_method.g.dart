// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interception_method.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HawkeyeInterceptionOptions _$HawkeyeInterceptionOptionsFromJson(Map<String, dynamic> json) =>
    HawkeyeInterceptionOptions(
      disableFormIntercept: json['disableFormIntercept'] as bool? ?? true,
      delayFormSubmitForFetch: json['delayFormSubmitForFetch'] as bool? ?? false,
      interceptionMethod:
          $enumDecodeNullable(_$HawkeyeInterceptionMethodEnumMap, json['interceptionMethod']) ??
          HawkeyeInterceptionMethod.PROXY,
    );

Map<String, dynamic> _$HawkeyeInterceptionOptionsToJson(HawkeyeInterceptionOptions instance) => <String, dynamic>{
  'disableFormIntercept': instance.disableFormIntercept,
  'delayFormSubmitForFetch': instance.delayFormSubmitForFetch,
  'interceptionMethod': _$HawkeyeInterceptionMethodEnumMap[instance.interceptionMethod]!,
};

const _$HawkeyeInterceptionMethodEnumMap = {
  HawkeyeInterceptionMethod.PROXY: 'PROXY',
  HawkeyeInterceptionMethod.DIRECT_REPLACEMENT: 'DIRECT_REPLACEMENT',
  HawkeyeInterceptionMethod.GETTER_SETTER: 'GETTER_SETTER',
};
