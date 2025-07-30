// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_claim.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProviderClaimData _$ProviderClaimDataFromJson(Map<String, dynamic> json) => ProviderClaimData(
  provider: json['provider'] as String,
  parameters: json['parameters'] as String,
  owner: json['owner'] as String,
  timestampS: (json['timestampS'] as num).toInt(),
  context: json['context'] as String,
  identifier: json['identifier'] as String,
  epoch: (json['epoch'] as num).toInt(),
);

Map<String, dynamic> _$ProviderClaimDataToJson(ProviderClaimData instance) => <String, dynamic>{
  'provider': instance.provider,
  'parameters': instance.parameters,
  'owner': instance.owner,
  'timestampS': instance.timestampS,
  'context': instance.context,
  'identifier': instance.identifier,
  'epoch': instance.epoch,
};

WitnessData _$WitnessDataFromJson(Map<String, dynamic> json) =>
    WitnessData(id: json['id'] as String, url: json['url'] as String);

Map<String, dynamic> _$WitnessDataToJson(WitnessData instance) => <String, dynamic>{
  'id': instance.id,
  'url': instance.url,
};

CreateClaimOutput _$CreateClaimOutputFromJson(Map<String, dynamic> json) => CreateClaimOutput(
  identifier: json['identifier'] as String,
  claimData: ProviderClaimData.fromJson(json['claimData'] as Map<String, dynamic>),
  signatures: (json['signatures'] as List<dynamic>).map((e) => e as String).toList(),
  witnesses: (json['witnesses'] as List<dynamic>).map((e) => WitnessData.fromJson(e as Map<String, dynamic>)).toList(),
  publicData: json['publicData'],
  taskId: (json['taskId'] as num?)?.toInt(),
  providerRequest: json['providerRequest'] == null
      ? null
      : DataProviderRequest.fromJson(json['providerRequest'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CreateClaimOutputToJson(CreateClaimOutput instance) => <String, dynamic>{
  'identifier': instance.identifier,
  'claimData': instance.claimData,
  'signatures': instance.signatures,
  'witnesses': instance.witnesses,
  'taskId': ?instance.taskId,
  'publicData': instance.publicData,
  'providerRequest': ?instance.providerRequest,
};
