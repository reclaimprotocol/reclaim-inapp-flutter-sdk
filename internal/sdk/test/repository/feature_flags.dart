import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_inapp_sdk/src/data/identity.dart';
import 'package:reclaim_inapp_sdk/src/overrides/overrides.dart';
import 'package:reclaim_inapp_sdk/src/repository/feature_flags.dart';
import 'package:reclaim_inapp_sdk/src/services/feature_flag.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('FeatureFlagRepository', () {
    late FeatureFlagRepository repository;
    late Map<String, Object> mockStorage;

    setUp(() {
      repository = FeatureFlagRepository();
      mockStorage = <String, Object>{};

      // Override SharedPreferences with test values
      SharedPreferences.setMockInitialValues(mockStorage);

      // Override storageAsync for tests
      FeatureFlagService.storageAsync = SharedPreferences.getInstance();
    });

    tearDown(() {
      mockStorage.clear();
      ReclaimOverride.clearAll();
    });

    group('getFeatureFlag', () {
      test('returns default value when no cached or local data exists', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        final result = await repository.getFeatureFlag(identity, FeatureFlag.isSingleClaimRequest);

        expect(result, false); // default value
      });

      test('returns overridden value when override is set', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        // Set override
        ReclaimOverride.set(const ReclaimFeatureFlagData(singleReclaimRequest: true));

        final result = await repository.getFeatureFlag(identity, FeatureFlag.isSingleClaimRequest);

        expect(result, true); // overridden value
      });

      test('returns cached value from local storage', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        // Pre-populate local storage
        await FeatureFlagService.setFeatureFlagsToLocal(identity, {'IS_SINGLE_RECLAIM_REQUEST': true}, (key) => false);

        final result = await repository.getFeatureFlag(identity, FeatureFlag.isSingleClaimRequest);

        expect(result, true);
      });

      test('handles error gracefully and returns default value', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        // Force an error by using corrupted data
        final prefs = await FeatureFlagService.storageAsync;
        await prefs.setString('feature-flags:appId=test-app&providerId=test-provider', 'invalid json');

        final result = await repository.getFeatureFlag(identity, FeatureFlag.isSingleClaimRequest);

        expect(result, false); // default value
      });

      test('supports different feature flag types - boolean', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        await FeatureFlagService.setFeatureFlagsToLocal(identity, {'canUseAiFlow': true}, (key) => false);

        final result = await repository.getFeatureFlag(identity, FeatureFlag.canUseAiFlow);

        expect(result, isA<bool>());
        expect(result, true);
      });

      test('supports different feature flag types - string', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        await FeatureFlagService.setFeatureFlagsToLocal(identity, {
          'attestor3BrowserRpcUrl': 'https://custom.url',
        }, (key) => false);

        final result = await repository.getFeatureFlag(identity, FeatureFlag.attestorBrowserRpcUrl);

        expect(result, isA<String>());
        expect(result, 'https://custom.url');
      });

      test('supports different feature flag types - int', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        await FeatureFlagService.setFeatureFlagsToLocal(identity, {
          'idleTimeThresholdForManualVerificationTrigger': 5,
        }, (key) => false);

        final result = await repository.getFeatureFlag(
          identity,
          FeatureFlag.idleTimeThresholdForManualVerificationTrigger,
        );

        expect(result, isA<int>());
        expect(result, 5);
      });

      test('supports nullable string feature flags', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        await FeatureFlagService.setFeatureFlagsToLocal(identity, {
          'manualReviewMessage': 'Custom message',
        }, (key) => false);

        final result = await repository.getFeatureFlag(identity, FeatureFlag.manualReviewMessage);

        expect(result, 'Custom message');
      });

      test('override takes precedence over local storage', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        // Set local value
        await FeatureFlagService.setFeatureFlagsToLocal(identity, {'singleReclaimRequest': false}, (key) => false);

        // Set override
        ReclaimOverride.set(const ReclaimFeatureFlagData(singleReclaimRequest: true));

        final result = await repository.getFeatureFlag(identity, FeatureFlag.isSingleClaimRequest);

        expect(result, true); // override value takes precedence
      });
    });

    group('setFeatureFlag', () {
      test('sets feature flag value correctly', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        await repository.setFeatureFlag(identity, FeatureFlag.canSaveWebStorageDev, true);

        final result = await repository.getFeatureFlag(identity, FeatureFlag.canSaveWebStorageDev);

        expect(result, true);
      });

      test('throws assertion error when setting remote-fetchable flag', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        expect(
          () => repository.setFeatureFlag(
            identity,
            FeatureFlag.isSingleClaimRequest, // canFetchFromRemote = true
            true,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('does not set value when override exists', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        // Set override
        ReclaimOverride.set(const ReclaimFeatureFlagData(cookiePersist: true));

        // Try to set a different value
        await repository.setFeatureFlag(identity, FeatureFlag.canSaveWebStorageDev, false);

        final result = await repository.getFeatureFlag(identity, FeatureFlag.canSaveWebStorageDev);

        expect(result, true); // override value, not the set value
      });

      test('persists value to local storage', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        await repository.setFeatureFlag(identity, FeatureFlag.canSaveWebStorageDev, true);

        // Verify it was saved to local storage
        final localFlags = await FeatureFlagService.getFeatureFlagsFromLocal(identity);
        expect(localFlags['cookiePersist'], true);
      });

      test('merges with existing flags', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        // Set first flag
        await repository.setFeatureFlag(identity, FeatureFlag.canSaveWebStorageDev, true);

        // Set another flag
        await repository.setFeatureFlag(identity, FeatureFlag.isWebInspectable, true);

        // Both should be retrievable
        final result1 = await repository.getFeatureFlag(identity, FeatureFlag.canSaveWebStorageDev);
        final result2 = await repository.getFeatureFlag(identity, FeatureFlag.isWebInspectable);

        expect(result1, true);
        expect(result2, true);
      });

      test('session independent flags persist across sessions', () async {
        const identity1 = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'session1');

        // Set session independent flag with identity1
        await repository.setFeatureFlag(
          identity1,
          FeatureFlag.canSaveWebStorageDev, // isSessionIndependent = true
          true,
        );

        // Verify it's available in session independent storage
        final sessionIndependentFlags = await FeatureFlagService.getSessionIndependentFeatureFlagsFromLocal();
        expect(sessionIndependentFlags['cookiePersist'], true);
      });
    });

    group('watchFeatureFlag', () {
      test('emits initial value', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        await FeatureFlagService.setFeatureFlagsToLocal(identity, {'cookiePersist': true}, (key) => false);

        final stream = repository.watchFeatureFlag(identity, FeatureFlag.canSaveWebStorageDev);

        await expectLater(stream.first, completion(true));
      });

      test('emits updated values when flag changes', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        final stream = repository.watchFeatureFlag(identity, FeatureFlag.canSaveWebStorageDev);

        final values = <bool>[];
        final subscription = stream.listen(values.add);

        // Wait for initial value
        await Future.delayed(const Duration(milliseconds: 100));

        // Update the flag
        await repository.setFeatureFlag(identity, FeatureFlag.canSaveWebStorageDev, true);

        await Future.delayed(const Duration(milliseconds: 100));

        await subscription.cancel();

        expect(values, contains(true));
      });

      test('creates unique stream controllers for different flags', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        final stream1 = repository.watchFeatureFlag(identity, FeatureFlag.canSaveWebStorageDev);

        final stream2 = repository.watchFeatureFlag(identity, FeatureFlag.isWebInspectable);

        expect(stream1, isNot(same(stream2)));
      });

      test('handles session independent flags correctly', () async {
        const identity1 = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'session1');

        const identity2 = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'session2');

        final stream1 = repository.watchFeatureFlag(
          identity1,
          FeatureFlag.canSaveWebStorageDev, // session independent
        );

        final stream2 = repository.watchFeatureFlag(identity2, FeatureFlag.canSaveWebStorageDev);

        final values1 = <bool>[];
        final values2 = <bool>[];
        final sub1 = stream1.listen(values1.add);
        final sub2 = stream2.listen(values2.add);

        await Future.delayed(const Duration(milliseconds: 100));

        // Update with identity1
        await repository.setFeatureFlag(identity1, FeatureFlag.canSaveWebStorageDev, true);

        await Future.delayed(const Duration(milliseconds: 100));

        await sub1.cancel();
        await sub2.cancel();

        // Both streams should receive the update since it's session independent
        expect(values1, contains(true));
        expect(values2, contains(true));
      });

      test('stream notifies all listeners when flag changes', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        final stream = repository.watchFeatureFlag(identity, FeatureFlag.canSaveWebStorageDev);

        final values1 = <bool>[];
        final values2 = <bool>[];

        final sub1 = stream.listen(values1.add);
        final sub2 = stream.listen(values2.add);

        await Future.delayed(const Duration(milliseconds: 100));

        await repository.setFeatureFlag(identity, FeatureFlag.canSaveWebStorageDev, true);

        await Future.delayed(const Duration(milliseconds: 100));

        await sub1.cancel();
        await sub2.cancel();

        // Both listeners should receive updates
        expect(values1, contains(true));
        expect(values2, contains(true));
      });
    });

    group('checkAndClearExpiredFlags', () {
      test('can be called without errors', () {
        expect(() => repository.checkAndClearExpiredFlags(), returnsNormally);
      });

      test('multiple calls do not cause errors', () {
        repository.checkAndClearExpiredFlags();
        repository.checkAndClearExpiredFlags();
        repository.checkAndClearExpiredFlags();

        // Should complete without errors
        expect(true, true);
      });
    });

    group('Edge Cases and Integration', () {
      test('handles multiple identities with separate caches', () async {
        const identity1 = SessionIdentity(appId: 'app1', providerId: 'provider1', sessionId: 'session1');

        const identity2 = SessionIdentity(appId: 'app2', providerId: 'provider2', sessionId: 'session2');

        await repository.setFeatureFlag(identity1, FeatureFlag.canSaveWebStorageDev, true);
        await repository.setFeatureFlag(identity2, FeatureFlag.canSaveWebStorageDev, false);

        final result1 = await repository.getFeatureFlag(identity1, FeatureFlag.canSaveWebStorageDev);
        final result2 = await repository.getFeatureFlag(identity2, FeatureFlag.canSaveWebStorageDev);

        expect(result1, true);
        expect(result2, false);
      });

      test('handles empty flag maps correctly', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        await FeatureFlagService.setFeatureFlagsToLocal(identity, {}, (key) => false);

        final result = await repository.getFeatureFlag(identity, FeatureFlag.isSingleClaimRequest);

        expect(result, false); // default value
      });

      test('static entries map contains all defined feature flags', () {
        // Verify that feature flags are properly registered
        expect(FeatureFlag.entries, isNotEmpty);
        expect(FeatureFlag.entries.containsKey('cookiePersist'), true);
        expect(FeatureFlag.entries.containsKey('attestor3BrowserRpcUrl'), true);
        expect(FeatureFlag.entries.containsKey('IS_SINGLE_RECLAIM_REQUEST'), true);
      });

      test('isFlagSessionIndependent correctly identifies session independent flags', () {
        expect(FeatureFlag.isFlagSessionIndependent('cookiePersist'), true);
        expect(FeatureFlag.isFlagSessionIndependent('IS_WEB_INSPECTABLE'), true);
        expect(FeatureFlag.isFlagSessionIndependent('IS_SINGLE_RECLAIM_REQUEST'), false);
      });

      test('handles concurrent getFeatureFlag calls', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        await FeatureFlagService.setFeatureFlagsToLocal(identity, {'canUseAiFlow': true}, (key) => false);

        // Make multiple concurrent calls
        final results = await Future.wait([
          repository.getFeatureFlag(identity, FeatureFlag.canUseAiFlow),
          repository.getFeatureFlag(identity, FeatureFlag.canUseAiFlow),
          repository.getFeatureFlag(identity, FeatureFlag.canUseAiFlow),
        ]);

        // All should return consistent results
        expect(results.length, 3);
        expect(results[0], true);
        expect(results[1], true);
        expect(results[2], true);
      });

      test('handles mixed session dependent and independent flags', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        // Set session independent flag
        await repository.setFeatureFlag(
          identity,
          FeatureFlag.canSaveWebStorageDev, // session independent
          true,
        );

        // Set session dependent flag (note: isWebInspectable is also session independent)
        await FeatureFlagService.setFeatureFlagsToLocal(
          identity,
          {'canUseAiFlow': false}, // session dependent
          (key) => false,
        );

        final result1 = await repository.getFeatureFlag(identity, FeatureFlag.canSaveWebStorageDev);
        final result2 = await repository.getFeatureFlag(identity, FeatureFlag.canUseAiFlow);

        expect(result1, true);
        expect(result2, false);
      });

      test('returns correct default values for all flag types', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        // Boolean flag
        final boolResult = await repository.getFeatureFlag(identity, FeatureFlag.isSingleClaimRequest);
        expect(boolResult, false);

        // String flag
        final stringResult = await repository.getFeatureFlag(identity, FeatureFlag.attestorBrowserRpcUrl);
        expect(stringResult, isA<String>());

        // Int flag
        final intResult = await repository.getFeatureFlag(
          identity,
          FeatureFlag.idleTimeThresholdForManualVerificationTrigger,
        );
        expect(intResult, 2);

        // Nullable string flag
        final nullableResult = await repository.getFeatureFlag(identity, FeatureFlag.manualReviewMessage);
        expect(nullableResult, isNull);
      });

      test('handles complex JSON structures in flags', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        final complexJson = '{"method": "form", "options": {"enabled": true}}';

        await FeatureFlagService.setFeatureFlagsToLocal(identity, {'interceptionOptions': complexJson}, (key) => false);

        final result = await repository.getFeatureFlag(identity, FeatureFlag.interceptionOptions);

        expect(result, complexJson);
      });
    });
  });
}
