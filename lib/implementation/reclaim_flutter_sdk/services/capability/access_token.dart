// Do not import flutter libraries in this file.

import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../overrides/override.dart';
import '../../utils/crypto/jws.dart';
import '../../utils/crypto/url_safe_codec.dart';

// taken from 'package:flutter/foundation.dart';
const bool
    _isDebugMode =
    !bool.fromEnvironment(
        'dart.vm.product');

// To let us verify with `/well-known/jwks.json` endpoint in future
const _issuer =
    String
        .fromEnvironment(
  'org.reclaimprotocol.inapp_sdk.CAPABILITY_ACCESS_TOKEN_ISSUER',
  defaultValue:
      'https://dev.reclaimprotocol.org',
);
const _audience =
    String
        .fromEnvironment(
  'org.reclaimprotocol.inapp_sdk.CAPABILITY_ACCESS_TOKEN_AUDIENCE',
  defaultValue:
      'org.reclaimprotocol.inapp_sdk',
);

class CapabilityAccessTokenException
    implements
        Exception {
  const CapabilityAccessTokenException(
      this.message);

  final String
      message;

  @override
  String
      toString() {
    return 'CapabilityAccessTokenException: $message';
  }
}

class InvalidCapabilityAccessTokenException
    extends CapabilityAccessTokenException {
  const InvalidCapabilityAccessTokenException(
      super.message);

  @override
  String
      toString() {
    return 'InvalidCapabilityAccessTokenException: $message';
  }
}

class ExpiredCapabilityAccessTokenException
    extends CapabilityAccessTokenException {
  const ExpiredCapabilityAccessTokenException(
      super.message);

  @override
  String
      toString() {
    return 'InvalidCapabilityAccessTokenException: $message';
  }
}

class CapabilityAccessToken
    extends ReclaimOverride<
        CapabilityAccessToken> {
  final ES256Jws
      accessToken;

  final Set<String>
      capabilities;
  final Set<Uri>
      authorizedParties;

  const CapabilityAccessToken._({
    required this.accessToken,
    required this.capabilities,
    required this.authorizedParties,
  });

  factory CapabilityAccessToken(
      {required ES256Jws
          accessToken}) {
    final nowInMs = DateTime.now()
        .toUtc()
        .millisecondsSinceEpoch;
    final now =
        (nowInMs / 1000).round();

    final payload =
        json.decode(utf8.decode(accessToken.payload));

    if (payload['iss'] != _issuer ||
        payload['aud'] != _audience) {
      throw const InvalidCapabilityAccessTokenException('Invalid iss or aud');
    }

    final nbf =
        payload['nbf'];
    final exp =
        payload['exp'];
    if (nbf is! int ||
        exp is! int) {
      throw const InvalidCapabilityAccessTokenException('Invalid nbf or exp or iat');
    }
    if (exp <
        now) {
      throw const ExpiredCapabilityAccessTokenException('Token expired');
    }
    final iat =
        payload['iat'];
    if (nbf > now ||
        iat is! int ||
        iat > now) {
      throw const InvalidCapabilityAccessTokenException('Token invalid');
    }

    final scope =
        payload['scope'];
    if (scope is! String ||
        scope.isEmpty) {
      throw const InvalidCapabilityAccessTokenException('Invalid scope');
    }
    // azp is optional
    final azp =
        payload['azp'] ?? "";
    if (azp
        is! String) {
      // not null and not a string means invalid
      throw const InvalidCapabilityAccessTokenException('Invalid azp');
    }
    final Set<String>
        capabilities =
        scope.split(' ').toSet();
    final Set<Uri> authorizedParties = azp
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => Uri.parse(e))
        .toSet();
    return CapabilityAccessToken
        ._(
      accessToken:
          accessToken,
      capabilities:
          capabilities,
      authorizedParties:
          authorizedParties,
    );
  }

  @override
  ReclaimOverride<CapabilityAccessToken>
      copyWith({ES256Jws? accessToken}) {
    return CapabilityAccessToken(
        accessToken: accessToken ?? this.accessToken);
  }

  factory CapabilityAccessToken.create(
    String
        privateKeyString,
    Set<String>
        capabilities,
    Set<String>
        authorizedParties, {
    required String
        sub,
    Duration expiresAfter =
        const Duration(days: 400),
  }) {
    final scope =
        capabilities.join(' ');
    final azp = authorizedParties
        .where((e) => e.isNotEmpty)
        .map((e) => Uri.parse(e).normalizePath().toString())
        .join(' ');

    final jti =
        Uuid().v4();
    final issuedAtDateTime =
        DateTime.now().toUtc();
    final issuedAt =
        issuedAtDateTime.millisecondsSinceEpoch ~/ 1000;
    final expiresAtDateTime =
        issuedAtDateTime.add(expiresAfter);
    final expiresAt =
        expiresAtDateTime.millisecondsSinceEpoch ~/ 1000;

    final payload =
        utf8.encode(
      json.encode({
        'jti': jti,
        'iss': _issuer,
        'aud': _audience,
        'iat': issuedAt,
        'nbf': issuedAt,
        'exp': expiresAt,
        'sub': sub,
        'scope': scope,
        if (azp.isNotEmpty)
          'azp': azp,
      }),
    );

    final privateKey = json.decode(utf8.decode(urlSafeDecode(privateKeyString))) as Map<
        String,
        dynamic>;

    final jws = ES256Jws.create(
        payload,
        privateKey);
    return CapabilityAccessToken(
        accessToken: jws);
  }

  factory CapabilityAccessToken.import(
      String
          accessTokenString,
      String
          publicKeyString) {
    try {
      final publicKey =
          json.decode(utf8.decode(urlSafeDecode(publicKeyString))) as Map<String, dynamic>;
      final jws =
          ES256Jws.import(accessTokenString, publicKey);
      return CapabilityAccessToken(accessToken: jws);
    } on CapabilityAccessTokenException {
      rethrow;
    } catch (e, s) {
      if (_isDebugMode) {
        // ignore: avoid_print
        print(e.toString());
        // ignore: avoid_print
        print(s.toString());
      }
      throw const CapabilityAccessTokenException('Invalid Capability Access Token');
    }
  }
}
