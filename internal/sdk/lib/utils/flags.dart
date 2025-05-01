import 'package:flutter/foundation.dart';
import 'package:reclaim_flutter_sdk/attestor.dart';
import 'package:reclaim_flutter_sdk/constants.dart';
import 'package:reclaim_flutter_sdk/logging/logging.dart';
import 'package:reclaim_flutter_sdk/overrides/overrides.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Flags {
  static const singleReclaimRequestKey = 'IS_SINGLE_RECLAIM_REQUEST';
  static const cookiePersistKey = 'cookiePersist';
  static const isWebInspectableKey = 'IS_WEB_INSPECTABLE';
  static const idleTimeThresholdKey =
      'IDLE_TIME_THRESHOLD_FOR_MANUAL_VERIFICATION_TRIGGER';
  static const sessionTimeoutForManualVerificationTriggerKey =
      'SESSION_TIMEOUT_FOR_MANUAL_VERIFICATION_TRIGGER';
  static const attestorBrowserRpcUrlKey = 'ATTESTOR_BROWSER_RPC_URL';
  static const isAIFlowEnabledKey = 'IS_AI_FLOW_ENABLED';
  static const _canUseAiFlowKey = 'canUseAiFlow';

  static bool isCookiePersist(SharedPreferences preferences) {
    return ReclaimOverrides.featureFlag?.cookiePersist ??
        preferences.getBool(cookiePersistKey) ??
        false;
  }

  static bool isSingleReclaimRequest(SharedPreferences preferences) {
    return ReclaimOverrides.featureFlag?.singleReclaimRequest ??
        preferences.getBool(singleReclaimRequestKey) ??
        false;
  }

  static int getIdleTimeThreshold(SharedPreferences preferences) {
    return preferences.getInt(idleTimeThresholdKey) ?? 10;
  }

  static bool isWebInspectable(SharedPreferences preferences) {
    return kDebugMode || (preferences.getBool(isWebInspectableKey) ?? false);
  }

  static int getSessionTimeoutForManualVerificationTrigger(
    SharedPreferences preferences,
  ) {
    return preferences.getInt(sessionTimeoutForManualVerificationTriggerKey) ??
        120;
  }

  static bool getCanUseAiFlow(SharedPreferences preferences) {
    return preferences.getBool(_canUseAiFlowKey) ?? true;
  }

  static Future<bool> setCanUseAiFlow(SharedPreferences preferences, bool value) {
    return preferences.setBool(_canUseAiFlowKey, value);
  }

  static String getAttestorBrowserRpcUrl(SharedPreferences preferences) {
    final url = preferences.getString(attestorBrowserRpcUrlKey);
    if (url != null && url.isNotEmpty) {
      return url;
    }
    return ReclaimBackend.DEFAULT_ATTESTOR_WEB_URL;
  }

  static bool isAIFlowEnabled(SharedPreferences preferences) {
    return preferences.getBool(isAIFlowEnabledKey) ?? false;
  }

  static Future<bool> setSingleReclaimRequest(
    bool value, [
    SharedPreferences? preferences,
  ]) async {
    preferences ??= await SharedPreferences.getInstance();
    return preferences.setBool(singleReclaimRequestKey, value);
  }

  static Future<bool> setCookiePersist(
    bool value, [
    SharedPreferences? preferences,
  ]) async {
    preferences ??= await SharedPreferences.getInstance();
    return preferences.setBool(cookiePersistKey, value);
  }

  static Future<bool> setIdleTimeThreshold(
    int value, [
    SharedPreferences? preferences,
  ]) async {
    preferences ??= await SharedPreferences.getInstance();
    return preferences.setInt(idleTimeThresholdKey, value);
  }

  static Future<bool> setIsWebInspectable(
    bool value, [
    SharedPreferences? preferences,
  ]) async {
    preferences ??= await SharedPreferences.getInstance();
    return preferences.setBool(isWebInspectableKey, value);
  }

  static Future<bool> setSessionTimeoutForManualVerificationTrigger(
    int value, [
    SharedPreferences? preferences,
  ]) async {
    preferences ??= await SharedPreferences.getInstance();
    return preferences.setInt(
      sessionTimeoutForManualVerificationTriggerKey,
      value,
    );
  }

  static Future<bool> setAttestorBrowserRpcUrl(
    String value, [
    SharedPreferences? preferences,
  ]) async {
    if (value.isEmpty) return false;
    preferences ??= await SharedPreferences.getInstance();
    return preferences.setString(attestorBrowserRpcUrlKey, value);
  }

  static Future<bool> setIsAIFlowEnabled(
    bool value, [
    SharedPreferences? preferences,
  ]) async {
    preferences ??= await SharedPreferences.getInstance();
    return preferences.setBool(isAIFlowEnabledKey, value);
  }

  static Future<void> setFlagsLocally(ReclaimFeatureFlagData options) async {
    final logger = logging.child('Flags.setFlagsLocally');
    final prefs = await SharedPreferences.getInstance();

    if (options.cookiePersist != null) {
      await Flags.setCookiePersist(options.cookiePersist!, prefs);
    }
    if (options.singleReclaimRequest != null) {
      await Flags.setSingleReclaimRequest(options.singleReclaimRequest!, prefs);
    }
    if (options.idleTimeThresholdForManualVerificationTrigger != null) {
      await Flags.setIdleTimeThreshold(
        options.idleTimeThresholdForManualVerificationTrigger!,
        prefs,
      );
    }
    if (options.sessionTimeoutForManualVerificationTrigger != null) {
      await Flags.setSessionTimeoutForManualVerificationTrigger(
        options.sessionTimeoutForManualVerificationTrigger!,
        prefs,
      );
    }
    if (options.canUseAiFlow != null) {
      await Flags.setCanUseAiFlow(prefs, options.canUseAiFlow == true);
    }
    if (options.attestorBrowserRpcUrl != null) {
      await Flags.setAttestorBrowserRpcUrl(
        options.attestorBrowserRpcUrl!,
        prefs,
      );
      final url = getAttestorBrowserRpcUrl(prefs);
      logger.info('Attestor URL: $url');
      Attestor.instance.setAttestorUrl(Uri.parse(url));
    }
    await Flags.setIsAIFlowEnabled(options.isAIFlowEnabled, prefs);
  }
}
