import 'dart:async';
import 'package:async/async.dart' show StreamGroup;
import 'package:flutter/foundation.dart';
import 'package:synchronized/synchronized.dart';
import '../constants.dart';
import '../data/identity.dart';
import '../logging/logging.dart';
import '../overrides/overrides.dart';
import '../services/feature_flag.dart';
import '../utils/restoration_identifier.dart';
import '../web_scripts/hawkeye/interception_method.dart';

typedef FeatureFlagSelector<T> = T? Function(ReclaimFeatureFlagData data);

class FeatureFlag<T> {
  final String key;
  final bool canFetchFromRemote;
  final T _valueIfNull;
  final FeatureFlagSelector<T>? _selector;
  final bool isSessionIndependent;

  FeatureFlag({
    required this.canFetchFromRemote,
    required this.key,
    FeatureFlagSelector<T>? selector,
    required T valueIfNull,
    this.isSessionIndependent = false,
  }) : _selector = selector,
       _valueIfNull = valueIfNull {
    FeatureFlag.entries[key] = this;
  }

  static final Map<String, FeatureFlag> entries = {};

  // only a developer override for testing purposes.
  static final canSaveWebStorageDev = FeatureFlag<bool>(
    key: 'cookiePersist',
    canFetchFromRemote: false,
    valueIfNull: false,
    isSessionIndependent: true,
    selector: (data) => data.cookiePersist,
  );

  static final attestorBrowserRpcUrl = FeatureFlag<String>(
    key: 'attestorBrowserRpcUrl',
    canFetchFromRemote: true,
    valueIfNull: ReclaimUrls.DEFAULT_ATTESTOR_WEB_URL,
    selector: (data) => data.attestorBrowserRpcUrl,
  );

  static final isSingleClaimRequest = FeatureFlag<bool>(
    key: 'IS_SINGLE_RECLAIM_REQUEST',
    canFetchFromRemote: true,
    valueIfNull: false,
    selector: (data) => data.singleReclaimRequest,
  );

  // only a developer override for testing purposes.
  static final isWebInspectable = FeatureFlag<bool>(
    key: 'IS_WEB_INSPECTABLE',
    canFetchFromRemote: false,
    isSessionIndependent: true,
    valueIfNull: false,
  );

  static final idleTimeThresholdForManualVerificationTrigger = FeatureFlag<int>(
    key: 'idleTimeThresholdForManualVerificationTrigger',
    canFetchFromRemote: true,
    valueIfNull: 2,
    selector: (data) => data.idleTimeThresholdForManualVerificationTrigger,
  );

  static final sessionTimeoutForManualVerificationTrigger = FeatureFlag<int>(
    key: 'sessionTimeoutForManualVerificationTrigger',
    canFetchFromRemote: true,
    valueIfNull: 120,
    selector: (data) => data.sessionTimeoutForManualVerificationTrigger,
  );

  static final manualReviewMessage = FeatureFlag<String?>(
    key: 'manualReviewMessage',
    canFetchFromRemote: true,
    valueIfNull: null,
    selector: (data) => data.manualReviewMessage,
  );

  static final loginPromptMessage = FeatureFlag<String?>(
    key: 'loginPromptMessage',
    canFetchFromRemote: true,
    valueIfNull: null,
    selector: (data) => data.loginPromptMessage,
  );

  static final canUseAiFlow = FeatureFlag<bool>(
    key: 'canUseAiFlow',
    canFetchFromRemote: true,
    valueIfNull: false,
    selector: (data) => data.canUseAiFlow,
  );

  static final hawkeyeInterceptionMethod = FeatureFlag<String>(
    key: 'hawkeyeInterceptionMethod',
    canFetchFromRemote: true,
    valueIfNull: HawkeyeInterceptionMethod.PROXY.name,
    selector: (data) => data.hawkeyeInterceptionMethod?.name,
  );

  static final claimCreationTimeoutDurationInMins = FeatureFlag<int>(
    key: 'claimCreationTimeoutDurationInMins',
    canFetchFromRemote: true,
    valueIfNull: 2,
    selector: (data) => data.claimCreationTimeoutDurationInMins,
  );

  static final sessionNoActivityTimeoutDurationInMins = FeatureFlag<int>(
    key: 'sessionNoActivityTimeoutDurationInMins',
    canFetchFromRemote: true,
    valueIfNull: 2,
    selector: (data) => data.sessionNoActivityTimeoutDurationInMins,
  );

  T _select(ReclaimFeatureFlagData data) => _selector?.call(data) ?? _valueIfNull;

  static bool isFlagSessionIndependent(String key) {
    return FeatureFlag.entries.values.any((e) => e.key == key && e.isSessionIndependent);
  }
}

T? _valueOrNull<T>(T? value) {
  if (value == null) return value;
  if (value is String) {
    if (value.trim().isEmpty) return null;
  }
  if (value is Map) {
    if (value.isEmpty) return null;
  }
  if (value is List) {
    if (value.isEmpty) return null;
  }
  return value;
}

class FeatureFlagRepository {
  final log = logging.child('FeatureFlagRepository');

  @protected
  T? getOverridenValue<T>(FeatureFlag<T> featureFlag) {
    final override = ReclaimOverrides.featureFlag;

    if (override == null) return null;

    return _valueOrNull(featureFlag._select(override));
  }

  static final _preferredFlagsCache = <SessionIdentity, Map<String, dynamic>>{};
  static var _preferredSessionIndependentFlagsCache = <String, dynamic>{};

  Future<void> _onUpdated(
    SessionIdentity identity,
    Map<String, dynamic> flags,
    Map<String, dynamic> sessionIndependentFlags,
  ) async {
    _preferredFlagsCache[identity] = flags;
    _preferredSessionIndependentFlagsCache = sessionIndependentFlags;

    final savingFlagsToLocal = FeatureFlagService.setFeatureFlagsToLocal(
      identity,
      flags,
      FeatureFlag.isFlagSessionIndependent,
    );

    final flagsForNotification = {...flags, ...sessionIndependentFlags};

    for (final entry in flagsForNotification.entries) {
      // ignore: close_sinks
      final ctrl = _getStreamController(identity, entry.key);
      if (ctrl != null) {
        ctrl.add(entry.value);
      }
    }

    await savingFlagsToLocal;
  }

  static final _fetchFlagsLock = Lock();

  static final Set<String> _freshFlags = <String>{};

  @protected
  Future<Map<String, dynamic>> fetchFlags(SessionIdentity identity, FeatureFlag<dynamic> featureFlag) async {
    return _fetchFlagsLock.synchronized(() async {
      final cachedFlags = _preferredFlagsCache[identity];

      log.finest('fetchFlag: ${featureFlag.key}, cachedFlags: ${cachedFlags?.keys}, _freshFlags: $_freshFlags');

      if (cachedFlags != null && _freshFlags.contains(featureFlag.key)) return cachedFlags;

      final localFlags = await FeatureFlagService.getFeatureFlagsFromLocal(identity);
      final flags = <String, dynamic>{...localFlags};
      final localSessionIndependentFlags = await FeatureFlagService.getSessionIndependentFeatureFlagsFromLocal();
      final sessionIndependentFlags = <String, dynamic>{...localSessionIndependentFlags};

      final updatingFlags = FeatureFlag.entries.values
          .where((it) {
            return it.canFetchFromRemote &&
                // don't have this key in in-memory cache
                !_freshFlags.contains(it.key);
          })
          .map((e) => e.key);
      try {
        final remoteFlags = await FeatureFlagService.getFeatureFlagsFromRemote(identity, updatingFlags).then((value) {
          return <String, dynamic>{...value}..removeWhere((k, v) => _valueOrNull(v) == null);
        });
        if (remoteFlags.isNotEmpty) {
          flags.addAll(remoteFlags);
          sessionIndependentFlags.addAll(remoteFlags);
        }
        _freshFlags.addAll(updatingFlags);
        log.finest('updatedFreshFlags: $_freshFlags');
      } catch (e, s) {
        log.severe('Failed to fetch feature flags from remote', e, s);
      }

      _onUpdated(identity, flags, sessionIndependentFlags);
      return flags;
    });
  }

  Future<T> getFeatureFlag<T>(SessionIdentity identity, FeatureFlag<T> featureFlag) async {
    final override = getOverridenValue(featureFlag);
    if (override != null) return override;

    try {
      if (featureFlag.isSessionIndependent) {
        final value = _valueOrNull(_preferredSessionIndependentFlagsCache[featureFlag.key]);
        if (value != null) {
          return value as T;
        }
      }

      final flags = await fetchFlags(identity, featureFlag);

      final value = _valueOrNull(flags[featureFlag.key]);

      if (value != null) {
        return value as T;
      }
    } catch (e, s) {
      log.severe('Failed to get feature flag ${featureFlag.key}', e, s);
    }
    return featureFlag._valueIfNull;
  }

  Future<void> setFeatureFlag<T>(SessionIdentity identity, FeatureFlag<T> featureFlag, T value) async {
    assert(!featureFlag.canFetchFromRemote, 'Cannot set feature flag $featureFlag because it is fetched from remote');

    final override = getOverridenValue(featureFlag);

    // do nothing for overriden flags
    if (override != null) return;

    final updated = {..._preferredFlagsCache[identity] ?? {}, featureFlag.key: value};

    final updatedSessionIndependent = {
      ..._preferredSessionIndependentFlagsCache,
      if (FeatureFlag.isFlagSessionIndependent(featureFlag.key)) featureFlag.key: value,
    };

    return _onUpdated(identity, updated, updatedSessionIndependent);
  }

  static final _controllers = <String, StreamController<dynamic>>{};

  String _getStreamIdentifier(SessionIdentity identity, String featureFlagKey) {
    if (FeatureFlag.isFlagSessionIndependent(featureFlagKey)) {
      return 'feature-flag-session-independent-$featureFlagKey';
    }
    return createRestorationIdentifier(
      'feature-flag',
      {...identity.toJson(), 'key': featureFlagKey}..remove('sessionId'),
    );
  }

  StreamController? _getStreamController<T>(SessionIdentity identity, String featureFlagKey) {
    final identifier = _getStreamIdentifier(identity, featureFlagKey);

    return _controllers[identifier];
  }

  StreamController _requireStreamController<T>(SessionIdentity identity, String featureFlagKey) {
    final identifier = _getStreamIdentifier(identity, featureFlagKey);

    // ignore: close_sinks
    final controller = _controllers.putIfAbsent(identifier, () => StreamController<T>.broadcast());

    return controller;
  }

  Stream<T> watchFeatureFlag<T>(SessionIdentity identity, FeatureFlag<T> featureFlag) {
    // ignore: close_sinks
    final controller = _requireStreamController(identity, featureFlag.key);

    final stream = getFeatureFlag(identity, featureFlag).asStream();

    final updatesStream = controller.stream.where((value) => value is T).cast<T>();

    return StreamGroup.merge([stream, updatesStream]);
  }
}
