// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttestorAuthenticationRequest
    _$AttestorAuthenticationRequestFromJson(
  Map<String,
          dynamic>
      json,
) =>
        AttestorAuthenticationRequest(
          data: json['data'] as Map<String, dynamic>,
          signature: json['signature'] == null ? null : AttestorBinaryData.fromJson(json['signature']),
        );

Map<String,
    dynamic> _$AttestorAuthenticationRequestToJson(
  AttestorAuthenticationRequest
      instance,
) =>
    <String, dynamic>{
      'data':
          instance.data,
      'signature':
          instance.signature
    };
