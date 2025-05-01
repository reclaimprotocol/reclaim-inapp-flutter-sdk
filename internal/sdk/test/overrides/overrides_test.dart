import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_flutter_sdk/overrides/overrides.dart';

class _TestingOverride extends ReclaimOverride<_TestingOverride> {
  final String? attestorBrowserRpcUrl;
  final bool? isInspectable;

  const _TestingOverride({
    required this.attestorBrowserRpcUrl,
    required this.isInspectable,
  });

  @override
  _TestingOverride copyWith({
    String? attestorBrowserRpcUrl,
    bool? isInspectable,
  }) {
    return _TestingOverride(
      attestorBrowserRpcUrl:
          attestorBrowserRpcUrl ?? this.attestorBrowserRpcUrl,
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
      final override = _TestingOverride(
        attestorBrowserRpcUrl: 'https://test.com',
        isInspectable: true,
      );

      ReclaimOverride.set(override);

      final retrieved = ReclaimOverride.get<_TestingOverride>();
      expect(retrieved, isNotNull);
      expect(retrieved!.attestorBrowserRpcUrl, 'https://test.com');
      expect(retrieved.isInspectable, true);
    });

    test('setAll overrides', () {
      final override1 = _TestingOverride(
        attestorBrowserRpcUrl: 'https://test1.com',
        isInspectable: true,
      );
      final override2 = _TestingOverride(
        attestorBrowserRpcUrl: 'https://test2.com',
        isInspectable: false,
      );

      ReclaimOverride.setAll([override1, override2]);

      final retrieved = ReclaimOverride.get<_TestingOverride>();
      expect(retrieved, isNotNull);
      // Should get the last override when multiple are set
      expect(retrieved!.attestorBrowserRpcUrl, 'https://test2.com');
      expect(retrieved.isInspectable, false);
    });

    test('get returns null for non-existent override', () {
      final retrieved = ReclaimOverride.get<_TestingOverride>();
      expect(retrieved, isNull);
    });

    test('override can be updated', () {
      final override1 = _TestingOverride(
        attestorBrowserRpcUrl: 'https://test1.com',
        isInspectable: true,
      );
      ReclaimOverride.set(override1);

      final override2 = _TestingOverride(
        attestorBrowserRpcUrl: 'https://test2.com',
        isInspectable: false,
      );
      ReclaimOverride.set(override2);

      final retrieved = ReclaimOverride.get<_TestingOverride>();
      expect(retrieved!.attestorBrowserRpcUrl, 'https://test2.com');
      expect(retrieved.isInspectable, false);
    });
  });

  group('_TestingOverride', () {
    test('copyWith updates specified fields', () {
      final original = _TestingOverride(
        attestorBrowserRpcUrl: 'https://test.com',
        isInspectable: true,
      );

      final copied = original.copyWith(
        attestorBrowserRpcUrl: 'https://new.com',
      );

      expect(copied.attestorBrowserRpcUrl, 'https://new.com');
      expect(copied.isInspectable, true); // Should retain original value
    });

    test('copyWith with null parameters retains original values', () {
      final original = _TestingOverride(
        attestorBrowserRpcUrl: 'https://test.com',
        isInspectable: true,
      );

      final copied = original.copyWith();

      expect(copied.attestorBrowserRpcUrl, 'https://test.com');
      expect(copied.isInspectable, true);
    });

    test('type getter returns correct type', () {
      final override = _TestingOverride(
        attestorBrowserRpcUrl: 'https://test.com',
        isInspectable: true,
      );

      expect(override.type, _TestingOverride);
    });
  });
}
