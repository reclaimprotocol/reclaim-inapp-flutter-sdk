import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_inapp_sdk/src/web_scripts/hawkeye/interception_method.dart';
import 'package:reclaim_inapp_sdk/src/webview_utils.dart';

void main() {
  group('HawkeyeInterceptionMethod', () {
    test('should return the correct method', () {
      expect(HawkeyeInterceptionMethod.fromString('PROXY'), HawkeyeInterceptionMethod.PROXY);
      expect(HawkeyeInterceptionMethod.fromString('proxy'), HawkeyeInterceptionMethod.PROXY);
      expect(HawkeyeInterceptionMethod.fromString('DIRECT_REPLACEMENT'), HawkeyeInterceptionMethod.DIRECT_REPLACEMENT);
      expect(HawkeyeInterceptionMethod.fromString('direct_replacement'), HawkeyeInterceptionMethod.DIRECT_REPLACEMENT);
      expect(HawkeyeInterceptionMethod.fromString('GETTER_SETTER'), HawkeyeInterceptionMethod.GETTER_SETTER);
      expect(HawkeyeInterceptionMethod.fromString('getter_setter'), HawkeyeInterceptionMethod.GETTER_SETTER);
      // default
      expect(HawkeyeInterceptionMethod.fromString('invalid'), HawkeyeInterceptionMethod.PROXY);
    });

    test('should return default values for properties', () {
      expect(HawkeyeInterceptionMethod.defaultMethod, HawkeyeInterceptionMethod.PROXY);
      expect(HawkeyeInterceptionMethod.defaultMethod.useProxyForFetch, isTrue);
      expect(HawkeyeInterceptionMethod.defaultMethod.useGetterForFetch, isFalse);
    });

    test('should return the correct method for useProxyForFetch', () {
      expect(HawkeyeInterceptionMethod.PROXY.useProxyForFetch, isTrue);
      expect(HawkeyeInterceptionMethod.DIRECT_REPLACEMENT.useProxyForFetch, isFalse);
      expect(HawkeyeInterceptionMethod.GETTER_SETTER.useProxyForFetch, isFalse);
    });

    test('should return the correct method for useGetterForFetch', () {
      expect(HawkeyeInterceptionMethod.PROXY.useGetterForFetch, isFalse);
      expect(HawkeyeInterceptionMethod.DIRECT_REPLACEMENT.useGetterForFetch, isFalse);
      expect(HawkeyeInterceptionMethod.GETTER_SETTER.useGetterForFetch, isTrue);
    });

    test('should apply options based on method in template', () {
      expect(applyMethodInTemplate(HawkeyeInterceptionMethod.PROXY, r'\(useProxyForFetch)'), 'true');
      expect(applyMethodInTemplate(HawkeyeInterceptionMethod.PROXY, r'\(useGetterForFetch)'), 'false');
      expect(applyMethodInTemplate(HawkeyeInterceptionMethod.DIRECT_REPLACEMENT, r'\(useProxyForFetch)'), 'false');
      expect(applyMethodInTemplate(HawkeyeInterceptionMethod.DIRECT_REPLACEMENT, r'\(useGetterForFetch)'), 'false');
      expect(applyMethodInTemplate(HawkeyeInterceptionMethod.GETTER_SETTER, r'\(useProxyForFetch)'), 'false');
      expect(applyMethodInTemplate(HawkeyeInterceptionMethod.GETTER_SETTER, r'\(useGetterForFetch)'), 'true');

      const template = r'''
const interceptor = new RequestInterceptor({
  disableFetch: false, // Set to true to disable fetch interception
  disableXHR: false, // Set to true to disable XHR interception
  useProxyForFetch: \(useProxyForFetch), // Set to false to use direct replacement instead of Proxy (default: true)
  useGetterForFetch: \(useGetterForFetch), // Set to true to use getter/setter approach (most robust)
});''';

      expect(applyMethodInTemplate(HawkeyeInterceptionMethod.PROXY, template), r'''
const interceptor = new RequestInterceptor({
  disableFetch: false, // Set to true to disable fetch interception
  disableXHR: false, // Set to true to disable XHR interception
  useProxyForFetch: true, // Set to false to use direct replacement instead of Proxy (default: true)
  useGetterForFetch: false, // Set to true to use getter/setter approach (most robust)
});''');
      expect(applyMethodInTemplate(HawkeyeInterceptionMethod.DIRECT_REPLACEMENT, template), r'''
const interceptor = new RequestInterceptor({
  disableFetch: false, // Set to true to disable fetch interception
  disableXHR: false, // Set to true to disable XHR interception
  useProxyForFetch: false, // Set to false to use direct replacement instead of Proxy (default: true)
  useGetterForFetch: false, // Set to true to use getter/setter approach (most robust)
});''');
      expect(applyMethodInTemplate(HawkeyeInterceptionMethod.GETTER_SETTER, template), r'''
const interceptor = new RequestInterceptor({
  disableFetch: false, // Set to true to disable fetch interception
  disableXHR: false, // Set to true to disable XHR interception
  useProxyForFetch: false, // Set to false to use direct replacement instead of Proxy (default: true)
  useGetterForFetch: true, // Set to true to use getter/setter approach (most robust)
});''');
    });
  });
}
