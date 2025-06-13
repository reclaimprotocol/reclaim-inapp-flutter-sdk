import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../data/identity.dart';
import '../logging/logging.dart';
import '../utils/dio.dart';
import '../utils/keys.dart';
import '../utils/restoration_identifier.dart';
import '../utils/storage.dart';

typedef IsSessionIndependentCallback = bool Function(String key);

class FeatureFlagService {
  static final Dio _dio = buildDio();

  static final log = logging.child('FeatureFlagService');

  // for keeping track of feature flag cache
  static void _updateRestorableFeatureFlagIdentifier(String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'feature-flags-identifiers';
    final list = <String>{...?prefs.getStringList(key), identifier};
    await prefs.setStringList(key, list.toList()..sort());
  }

  static String _getRestorableFeatureFlagIdentifier(SessionIdentity identity) {
    final identifier = createRestorationIdentifier('feature-flags', {...identity.toJson()}..remove('sessionId'));
    _updateRestorableFeatureFlagIdentifier(identifier);
    return identifier;
  }

  static String _getRestorableSessionIndependentFeatureFlagIdentifier() {
    return 'feature-flags-session-independent';
  }

  static Future<Map<String, dynamic>> getFeatureFlagsFromLocal(SessionIdentity identity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final identifier = _getRestorableFeatureFlagIdentifier(identity);

      final String? cached = prefs.getString(identifier);

      if (cached == null || cached.isEmpty) return const {};

      return json.decode(cached);
    } catch (e, s) {
      log.severe('Error fetching feature flags from local', e, s);
      return const {};
    }
  }

  static Future<Map<String, dynamic>> getSessionIndependentFeatureFlagsFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final String? cached = prefs.getString(_getRestorableSessionIndependentFeatureFlagIdentifier());

      if (cached == null || cached.isEmpty) return const {};

      return json.decode(cached);
    } catch (e, s) {
      log.severe('Error fetching session independent feature flags from local', e, s);
      return const {};
    }
  }

  static Future<void> setFeatureFlagsToLocal(
    SessionIdentity identity,
    Map<String, dynamic> flags,
    IsSessionIndependentCallback isSessionIndependent,
  ) async {
    try {
      final identifier = _getRestorableFeatureFlagIdentifier(identity);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(identifier, json.encode(flags));
      final sessionIndependentEntries = Map.fromEntries(flags.entries.where((e) => isSessionIndependent(e.key)));
      if (sessionIndependentEntries.isNotEmpty) {
        await prefs.setString(
          _getRestorableSessionIndependentFeatureFlagIdentifier(),
          json.encode(sessionIndependentEntries),
        );
      }
    } catch (e, s) {
      log.severe('Error setting feature flags to local', e, s);
    }
  }

  static Future<Map<String, dynamic>> getFeatureFlagsFromRemote(
    SessionIdentity identity,
    Iterable<String> featureFlagNames,
  ) async {
    if (featureFlagNames.isEmpty) return const {};

    const storage = ReclaimStorage();
    final String privateKey = await storage.getData('ReclaimOwnerPrivateKey');
    final String publicKey = getPublicKey(privateKey);
    logging.child('FeatureFlags').info('Extracted public key: $publicKey, SessionIdentity: $identity');
    try {
      return await FeatureFlagService.fetchFeatureFlagsFromServer(
        featureFlagNames: featureFlagNames.toSet().toList(),
        appId: identity.appId,
        providerId: identity.providerId,
        sessionId: identity.sessionId,
        publicKey: publicKey,
      );
    } catch (e, s) {
      logging.child('FeatureFlags').severe('Error fetching feature flags', e, s);
      return const {};
    }
  }

  static Future<Map<String, dynamic>> fetchFeatureFlagsFromServer({
    required List<String> featureFlagNames,
    String? publicKey,
    String? appId,
    String? providerId,
    String? sessionId,
  }) async {
    final queryParams = {
      if (publicKey != null) 'publicKey': publicKey,
      'featureFlagNames': featureFlagNames,
      if (appId != null) 'appId': appId,
      if (providerId != null) 'providerId': providerId,
      if (sessionId != null) 'sessionId': sessionId,
    };

    try {
      final response = await _dio.get(
        '${ReclaimUrls.FEATURE_FLAGS_API}/get',
        queryParameters: queryParams,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = response.data as List<dynamic>;
        final Map<String, dynamic> featureFlags = {};

        for (var flag in responseData) {
          if (flag is Map<String, dynamic>) {
            final String flagName = flag['name'] as String;
            final dynamic flagValue = flag['value'];
            if (flag['type'] == 'boolean') {
              featureFlags[flagName] = flagValue as bool? ?? false;
            } else if (flag['type'] == 'string') {
              featureFlags[flagName] = flagValue as String? ?? '';
            } else if (flag['type'] == 'number') {
              featureFlags[flagName] = flagValue as int? ?? 0;
            }
          }
        }

        return featureFlags;
      } else {
        throw Exception('Failed to load feature flags: ${response.statusCode}');
      }
    } catch (e) {
      logging.child('FeatureFlags').severe('Error fetching feature flags: $e');
      return {};
    }
  }
}
