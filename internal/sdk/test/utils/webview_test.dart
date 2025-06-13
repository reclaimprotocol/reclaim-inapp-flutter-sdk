import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_inapp_sdk/src/data/providers.dart';
import 'package:reclaim_inapp_sdk/src/webview_utils.dart';

void testResult(ConvertedTemplateResult actual, ConvertedTemplateResult expected) {
  expect(actual.$1, expected.$1);
  expect(actual.$2, expected.$2);
  expect(actual.$3, expected.$3);
}

void main() {
  group('convertTemplateToRegex', () {
    test('should create regex template', () {
      testResult(convertTemplateToRegex(template: '{{name}}'), ('(.*?)', ['name'], ['name']));
      testResult(convertTemplateToRegex(template: '{{name}}', matchTypeOverride: MatchType.LAZY), (
        '(.*?)',
        ['name'],
        ['name'],
      ));
      testResult(convertTemplateToRegex(template: '{{name}}', matchTypeOverride: MatchType.GREEDY), (
        '(.*)',
        ['name'],
        ['name'],
      ));
      testResult(convertTemplateToRegex(template: '{{name_GRD}}'), ('(.*)', ['name_GRD'], ['name_GRD']));
      testResult(convertTemplateToRegex(template: '{{name_GRD}}', matchTypeOverride: MatchType.LAZY), (
        '(.*)',
        ['name_GRD'],
        ['name_GRD'],
      ));
      testResult(convertTemplateToRegex(template: '{{name}}', parameters: {'name': 'example'}), (
        'example',
        ['name'],
        [],
      ));
      testResult(convertTemplateToRegex(template: ''), ('', [], []));
      testResult(convertTemplateToRegex(template: 'name'), ('name', [], []));
      testResult(convertTemplateToRegex(template: '{{hello}} {{world}}'), (
        '(.*?) (.*?)',
        ['hello', 'world'],
        ['hello', 'world'],
      ));
      testResult(convertTemplateToRegex(template: '{{hello}} {{world}}', parameters: {'hello': 'hi'}), (
        'hi (.*?)',
        ['hello', 'world'],
        ['world'],
      ));
      testResult(
        convertTemplateToRegex(template: '{{hello}} {{world}}', parameters: {'hello': 'hi', 'world': 'there'}),
        ('hi there', ['hello', 'world'], []),
      );
    });
  });
}
