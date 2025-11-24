import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_inapp_sdk/src/overrides/overrides.dart';

class _TestingOverride extends ReclaimOverride<_TestingOverride> {
  final String? attestor3BrowserRpcUrl;
  final bool? isInspectable;

  const _TestingOverride({required this.attestor3BrowserRpcUrl, required this.isInspectable});

  @override
  _TestingOverride copyWith({String? attestor3BrowserRpcUrl, bool? isInspectable}) {
    return _TestingOverride(
      attestor3BrowserRpcUrl: attestor3BrowserRpcUrl ?? this.attestor3BrowserRpcUrl,
      isInspectable: isInspectable ?? this.isInspectable,
    );
  }
}

void main() {
  group('ReclaimOverride', () {
    tearDown(() {
      // Reset overrides after each test
      ReclaimOverride.clearAll();
    });

    test('set single override', () {
      final override = const _TestingOverride(attestor3BrowserRpcUrl: 'https://test.com', isInspectable: true);

      ReclaimOverride.set(override);

      final retrieved = ReclaimOverride.get<_TestingOverride>();
      expect(retrieved, isNotNull);
      expect(retrieved!.attestor3BrowserRpcUrl, 'https://test.com');
      expect(retrieved.isInspectable, true);
    });

    test('setAll overrides', () {
      final override1 = const _TestingOverride(attestor3BrowserRpcUrl: 'https://test1.com', isInspectable: true);
      final override2 = const _TestingOverride(attestor3BrowserRpcUrl: 'https://test2.com', isInspectable: false);

      ReclaimOverride.setAll([override1, override2]);

      final retrieved = ReclaimOverride.get<_TestingOverride>();
      expect(retrieved, isNotNull);
      // Should get the last override when multiple are set
      expect(retrieved!.attestor3BrowserRpcUrl, 'https://test2.com');
      expect(retrieved.isInspectable, false);
    });

    test('get returns null for non-existent override', () {
      final retrieved = ReclaimOverride.get<_TestingOverride>();
      expect(retrieved, isNull);
    });

    test('override can be updated', () {
      final override1 = const _TestingOverride(attestor3BrowserRpcUrl: 'https://test1.com', isInspectable: true);
      ReclaimOverride.set(override1);

      final override2 = const _TestingOverride(attestor3BrowserRpcUrl: 'https://test2.com', isInspectable: false);
      ReclaimOverride.set(override2);

      final retrieved = ReclaimOverride.get<_TestingOverride>();
      expect(retrieved!.attestor3BrowserRpcUrl, 'https://test2.com');
      expect(retrieved.isInspectable, false);
    });
  });

  group('_TestingOverride', () {
    test('copyWith updates specified fields', () {
      final original = const _TestingOverride(attestor3BrowserRpcUrl: 'https://test.com', isInspectable: true);

      final copied = original.copyWith(attestor3BrowserRpcUrl: 'https://new.com');

      expect(copied.attestor3BrowserRpcUrl, 'https://new.com');
      expect(copied.isInspectable, true); // Should retain original value
    });

    test('copyWith with null parameters retains original values', () {
      final original = const _TestingOverride(attestor3BrowserRpcUrl: 'https://test.com', isInspectable: true);

      final copied = original.copyWith();

      expect(copied.attestor3BrowserRpcUrl, 'https://test.com');
      expect(copied.isInspectable, true);
    });

    test('type getter returns correct type', () {
      final override = const _TestingOverride(attestor3BrowserRpcUrl: 'https://test.com', isInspectable: true);

      expect(override.type, _TestingOverride);
    });
  });
}
