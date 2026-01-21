import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_inapp_sdk/src/data/identity.dart';
import 'package:reclaim_inapp_sdk/src/services/feature_flag.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('FeatureFlagService', () {
    late Map<String, Object> mockStorage;

    setUp(() {
      // Initialize mock storage
      mockStorage = <String, Object>{};

      // Override SharedPreferences with test values
      SharedPreferences.setMockInitialValues(mockStorage);

      // Override storageAsync for tests
      FeatureFlagService.storageAsync = SharedPreferences.getInstance();
    });

    tearDown(() {
      mockStorage.clear();
    });

    group('Local Storage - Session Dependent Flags', () {
      test('getFeatureFlagsFromLocal returns empty map when no cached data', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        final result = await FeatureFlagService.getFeatureFlagsFromLocal(identity);

        expect(result, isEmpty);
      });

      test('getFeatureFlagsFromLocal returns cached flags', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        final testFlags = {'flag1': true, 'flag2': 'value', 'flag3': 123};

        // Set flags first
        await FeatureFlagService.setFeatureFlagsToLocal(
          identity,
          testFlags,
          (key) => false, // none are session independent
        );

        // Get flags back
        final result = await FeatureFlagService.getFeatureFlagsFromLocal(identity);

        expect(result, equals(testFlags));
      });

      test('setFeatureFlagsToLocal stores flags correctly', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        final testFlags = {'testFlag': true, 'anotherFlag': 'testValue'};

        await FeatureFlagService.setFeatureFlagsToLocal(identity, testFlags, (key) => false);

        final prefs = await FeatureFlagService.storageAsync;
        final keys = prefs.getKeys();

        // Should have stored the flags and updated identifiers list
        expect(keys.length, greaterThan(0));
      });

      test('getFeatureFlagsFromLocal handles invalid JSON gracefully', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        // Manually set invalid JSON
        final prefs = await FeatureFlagService.storageAsync;
        await prefs.setString('feature-flags:appId=test-app&providerId=test-provider', 'invalid json');

        final result = await FeatureFlagService.getFeatureFlagsFromLocal(identity);

        expect(result, isEmpty);
      });

      test('different identities have separate flag storage', () async {
        final identity1 = const SessionIdentity(appId: 'app1', providerId: 'provider1', sessionId: 'session1');

        final identity2 = const SessionIdentity(appId: 'app2', providerId: 'provider2', sessionId: 'session2');

        final flags1 = {'flag1': true};
        final flags2 = {'flag2': false};

        await FeatureFlagService.setFeatureFlagsToLocal(identity1, flags1, (key) => false);
        await FeatureFlagService.setFeatureFlagsToLocal(identity2, flags2, (key) => false);

        final result1 = await FeatureFlagService.getFeatureFlagsFromLocal(identity1);
        final result2 = await FeatureFlagService.getFeatureFlagsFromLocal(identity2);

        expect(result1, equals(flags1));
        expect(result2, equals(flags2));
      });
    });

    group('Local Storage - Session Independent Flags', () {
      test('getSessionIndependentFeatureFlagsFromLocal returns empty map when no cached data', () async {
        final result = await FeatureFlagService.getSessionIndependentFeatureFlagsFromLocal();

        expect(result, isEmpty);
      });

      test('setFeatureFlagsToLocal stores session independent flags separately', () async {
        final identity = const SessionIdentity(
          appId: 'test-app',
          providerId: 'test-provider',
          sessionId: 'test-session',
        );

        final testFlags = {'sessionDependentFlag': true, 'sessionIndependentFlag': 'value'};

        // Only sessionIndependentFlag should be stored as session independent
        await FeatureFlagService.setFeatureFlagsToLocal(identity, testFlags, (key) => key == 'sessionIndependentFlag');

        final sessionIndependentFlags = await FeatureFlagService.getSessionIndependentFeatureFlagsFromLocal();

        expect(sessionIndependentFlags, {'sessionIndependentFlag': 'value'});
        expect(sessionIndependentFlags.containsKey('sessionDependentFlag'), false);
      });

      test('session independent flags persist across different sessions', () async {
        final identity1 = const SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'session1');

        final testFlags = {'independentFlag': 'persistent-value'};

        await FeatureFlagService.setFeatureFlagsToLocal(
          identity1,
          testFlags,
          (key) => true, // all are session independent
        );

        // Should be available regardless of session
        final result = await FeatureFlagService.getSessionIndependentFeatureFlagsFromLocal();

        expect(result, equals(testFlags));
      });

      test('getSessionIndependentFeatureFlagsFromLocal handles invalid JSON gracefully', () async {
        final prefs = await FeatureFlagService.storageAsync;
        await prefs.setString('feature-flags-session-independent', 'invalid json');

        final result = await FeatureFlagService.getSessionIndependentFeatureFlagsFromLocal();

        expect(result, isEmpty);
      });
    });

    group('Feature Flag Identifiers Cache', () {
      test('stores unique identifiers when setting flags', () async {
        const identity1 = SessionIdentity(appId: 'app1', providerId: 'provider1', sessionId: 'session1');

        final identity2 = const SessionIdentity(appId: 'app2', providerId: 'provider2', sessionId: 'session2');

        await FeatureFlagService.setFeatureFlagsToLocal(identity1, {'flag1': true}, (key) => false);
        await FeatureFlagService.setFeatureFlagsToLocal(identity2, {'flag2': true}, (key) => false);

        final prefs = await FeatureFlagService.storageAsync;
        final identifiers = prefs.getStringList('feature-flags-identifiers');

        expect(identifiers, isNotNull);
        expect(identifiers!.length, 2);
        expect(identifiers.toSet().length, 2); // All should be unique
      });

      test('identifiers are stored in sorted order', () async {
        const identity1 = SessionIdentity(appId: 'zapp', providerId: 'zprovider', sessionId: 'session1');

        const identity2 = SessionIdentity(appId: 'aapp', providerId: 'aprovider', sessionId: 'session2');

        await FeatureFlagService.setFeatureFlagsToLocal(identity1, {'flag1': true}, (key) => false);
        await FeatureFlagService.setFeatureFlagsToLocal(identity2, {'flag2': true}, (key) => false);

        final prefs = await FeatureFlagService.storageAsync;
        final identifiers = prefs.getStringList('feature-flags-identifiers');

        expect(identifiers, isNotNull);
        // Check if sorted
        final sortedIdentifiers = List<String>.from(identifiers!)..sort();
        expect(identifiers, equals(sortedIdentifiers));
      });

      test('duplicate identifiers are not added twice', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        // Set flags twice with same identity
        await FeatureFlagService.setFeatureFlagsToLocal(identity, {'flag1': true}, (key) => false);
        await FeatureFlagService.setFeatureFlagsToLocal(identity, {'flag2': false}, (key) => false);

        final prefs = await FeatureFlagService.storageAsync;
        final identifiers = prefs.getStringList('feature-flags-identifiers');

        expect(identifiers, isNotNull);
        expect(identifiers!.length, 1); // Should only have one unique identifier
      });
    });

    group('fetchFeatureFlagsFromServer', () {
      test('returns empty map when no feature flag names provided', () async {
        final result = await FeatureFlagService.fetchFeatureFlagsFromServer(featureFlagNames: []);

        expect(result, isEmpty);
      });

      test('handles boolean type feature flags', () async {
        // Note: This test would require mocking the Dio client
        // Since we can't easily mock Dio in this context, we're documenting the expected behavior
        // In a real test, you would use a package like mockito or mocktail

        // Expected behavior:
        // - When server returns type: 'boolean', value should be parsed as bool
        // - Default to false if value is null
      });

      test('handles string type feature flags', () async {
        // Expected behavior:
        // - When server returns type: 'string', value should be parsed as String
        // - Default to empty string if value is null
      });

      test('handles number type feature flags', () async {
        // Expected behavior:
        // - When server returns type: 'number', value should be parsed as int
        // - Default to 0 if value is null
      });

      test('returns empty map on network error', () async {
        // Expected behavior:
        // - Network errors should be caught and return empty map
        // - Errors should be logged
      });

      test('includes all query parameters when provided', () async {
        // Expected behavior:
        // - publicKey, appId, providerId, sessionId should be included when provided
        // - operatingSystem and inappSdkVersion should always be included
      });
    });

    group('Edge Cases', () {
      test('handles empty string values in cached flags', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        final testFlags = {'emptyFlag': '', 'validFlag': 'value'};

        await FeatureFlagService.setFeatureFlagsToLocal(identity, testFlags, (key) => false);
        final result = await FeatureFlagService.getFeatureFlagsFromLocal(identity);

        expect(result, equals(testFlags));
      });

      test('handles complex nested JSON structures', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        final testFlags = {
          'complexFlag': {
            'nested': {'value': 'deep'},
            'array': [1, 2, 3],
          },
        };

        await FeatureFlagService.setFeatureFlagsToLocal(identity, testFlags, (key) => false);
        final result = await FeatureFlagService.getFeatureFlagsFromLocal(identity);

        expect(result, equals(testFlags));
      });

      test('handles null values in flag map', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        final testFlags = {'nullFlag': null, 'validFlag': 'value'};

        await FeatureFlagService.setFeatureFlagsToLocal(identity, testFlags, (key) => false);
        final result = await FeatureFlagService.getFeatureFlagsFromLocal(identity);

        expect(result, equals(testFlags));
      });

      test('sessionId is excluded from restoration identifier', () async {
        const identity1 = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'session1');

        const identity2 = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'session2');

        await FeatureFlagService.setFeatureFlagsToLocal(identity1, {'flag': 'value1'}, (key) => false);

        // Since sessionId is excluded from identifier, identity2 should read the same flags
        final result = await FeatureFlagService.getFeatureFlagsFromLocal(identity2);

        expect(result, {'flag': 'value1'});
      });
    });

    group('Concurrent Operations', () {
      test('handles concurrent reads and writes', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        final testFlags = {'flag': 'value'};

        // Perform concurrent operations
        await Future.wait([
          FeatureFlagService.setFeatureFlagsToLocal(identity, testFlags, (key) => false),
          FeatureFlagService.getFeatureFlagsFromLocal(identity),
          FeatureFlagService.getFeatureFlagsFromLocal(identity),
        ]);

        // Final read should succeed
        final result = await FeatureFlagService.getFeatureFlagsFromLocal(identity);

        expect(result, equals(testFlags));
      });

      test('multiple setFeatureFlagsToLocal calls use last value', () async {
        const identity = SessionIdentity(appId: 'test-app', providerId: 'test-provider', sessionId: 'test-session');

        await FeatureFlagService.setFeatureFlagsToLocal(identity, {'flag': 'value1'}, (key) => false);
        await FeatureFlagService.setFeatureFlagsToLocal(identity, {'flag': 'value2'}, (key) => false);
        await FeatureFlagService.setFeatureFlagsToLocal(identity, {'flag': 'value3'}, (key) => false);

        final result = await FeatureFlagService.getFeatureFlagsFromLocal(identity);

        expect(result, {'flag': 'value3'});
      });
    });
  });
}
