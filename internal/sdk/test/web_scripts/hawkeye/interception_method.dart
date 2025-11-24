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
  });

  group('HawkeyeInterceptionOptions', () {
    test('should have correct default values', () {
      const options = HawkeyeInterceptionOptions();
      expect(options.disableFormIntercept, isFalse);
      expect(options.delayFormSubmitForFetch, isTrue);
      expect(options.interceptionMethod, HawkeyeInterceptionMethod.PROXY);
    });

    test('should apply options based on method in template', () {
      const proxyOptions = HawkeyeInterceptionOptions(interceptionMethod: HawkeyeInterceptionMethod.PROXY);
      const directOptions = HawkeyeInterceptionOptions(
        interceptionMethod: HawkeyeInterceptionMethod.DIRECT_REPLACEMENT,
      );
      const getterOptions = HawkeyeInterceptionOptions(interceptionMethod: HawkeyeInterceptionMethod.GETTER_SETTER);

      expect(applyInterceptorOptionsToTemplate(proxyOptions, r'\(useProxyForFetch)'), 'true');
      expect(applyInterceptorOptionsToTemplate(proxyOptions, r'\(useGetterForFetch)'), 'false');
      expect(applyInterceptorOptionsToTemplate(directOptions, r'\(useProxyForFetch)'), 'false');
      expect(applyInterceptorOptionsToTemplate(directOptions, r'\(useGetterForFetch)'), 'false');
      expect(applyInterceptorOptionsToTemplate(getterOptions, r'\(useProxyForFetch)'), 'false');
      expect(applyInterceptorOptionsToTemplate(getterOptions, r'\(useGetterForFetch)'), 'true');

      const template = r'''
    const interceptor = new RequestInterceptor({
      disableFormIntercept: \(disableFormIntercept),
      delayFormSubmitForFetch: \(delayFormSubmitForFetch),
      useProxyForFetch: \(useProxyForFetch), // Set to false to use direct replacement instead of Proxy (default: true)
      useGetterForFetch: \(useGetterForFetch), // Set to true to use getter/setter approach (most robust)
    });''';

      expect(applyInterceptorOptionsToTemplate(proxyOptions, template), r'''
    const interceptor = new RequestInterceptor({
      disableFormIntercept: false,
      delayFormSubmitForFetch: true,
      useProxyForFetch: true, // Set to false to use direct replacement instead of Proxy (default: true)
      useGetterForFetch: false, // Set to true to use getter/setter approach (most robust)
    });''');
      expect(applyInterceptorOptionsToTemplate(directOptions, template), r'''
    const interceptor = new RequestInterceptor({
      disableFormIntercept: false,
      delayFormSubmitForFetch: true,
      useProxyForFetch: false, // Set to false to use direct replacement instead of Proxy (default: true)
      useGetterForFetch: false, // Set to true to use getter/setter approach (most robust)
    });''');
      expect(applyInterceptorOptionsToTemplate(getterOptions, template), r'''
    const interceptor = new RequestInterceptor({
      disableFormIntercept: false,
      delayFormSubmitForFetch: true,
      useProxyForFetch: false, // Set to false to use direct replacement instead of Proxy (default: true)
      useGetterForFetch: true, // Set to true to use getter/setter approach (most robust)
    });''');
    });

    test('should apply custom options in template', () {
      const customOptions = HawkeyeInterceptionOptions(
        disableFormIntercept: true,
        delayFormSubmitForFetch: false,
        interceptionMethod: HawkeyeInterceptionMethod.GETTER_SETTER,
      );

      const template = r'''
    const interceptor = new RequestInterceptor({
      disableFormIntercept: \(disableFormIntercept),
      delayFormSubmitForFetch: \(delayFormSubmitForFetch),
      useProxyForFetch: \(useProxyForFetch),
      useGetterForFetch: \(useGetterForFetch),
    });''';

      expect(applyInterceptorOptionsToTemplate(customOptions, template), r'''
    const interceptor = new RequestInterceptor({
      disableFormIntercept: true,
      delayFormSubmitForFetch: false,
      useProxyForFetch: false,
      useGetterForFetch: true,
    });''');
    });
  });
}
