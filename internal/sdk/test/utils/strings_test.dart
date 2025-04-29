import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_flutter_sdk/utils/strings.dart';

void main() {
  group('interpolateParamsInTemplate', () {
    test('Interpolate params in template with lowercase', () {
      expect(
        interpolateParamsInTemplate('%7B%7Burl_param_domain%7D%7D.com', {
          'URL_PARAM_DOMAIN': 'x',
          'DATA_1': 'data1',
          'DATA_2': 'data2',
        }),
        'x.com',
      );
    });

    test('Interpolate params in template', () {
      expect(
        interpolateParamsInTemplate(
            'https://{{PARAMS_URL}}.com/dashboard/{{DATA_1}}/{{DATA_2}}', {
          'PARAMS_URL': 'example',
          'DATA_1': 'data1',
          'DATA_2': 'data2',
        }),
        'https://example.com/dashboard/data1/data2',
      );
    });

    test('Handle empty params map', () {
      expect(
        interpolateParamsInTemplate('https://{{PARAMS_URL}}.com', {}),
        'https://{{PARAMS_URL}}.com',
      );
    });

    test('Handle missing params', () {
      expect(
        interpolateParamsInTemplate(
            'https://{{PARAMS_URL}}.com/{{MISSING_PARAM}}', {
          'PARAMS_URL': 'example',
        }),
        'https://example.com/{{MISSING_PARAM}}',
      );
    });

    test('Handle template with no parameters', () {
      expect(
        interpolateParamsInTemplate('https://example.com', {
          'PARAMS_URL': 'test',
        }),
        'https://example.com',
      );
    });

    test('Handle multiple occurrences of same parameter', () {
      expect(
        interpolateParamsInTemplate(
            'https://{{DOMAIN}}.com/{{PATH}}/{{DOMAIN}}', {
          'DOMAIN': 'example',
          'PATH': 'test',
        }),
        'https://example.com/test/example',
      );
    });

    test('Handle special characters in parameters', () {
      expect(
        interpolateParamsInTemplate('https://{{DOMAIN}}.com/{{PATH}}', {
          'DOMAIN': 'example!@#',
          'PATH': 'test/path?param=1&other=2',
        }),
        'https://example!@#.com/test/path?param=1&other=2',
      );
    });
  });
}
