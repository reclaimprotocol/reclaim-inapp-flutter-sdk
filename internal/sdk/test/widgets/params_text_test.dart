import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_inapp_sdk/src/widgets/params/string.dart';

void main() {
  group('formatParamsLabel', () {
    test('lowercase single word', () {
      expect(formatParamsLabel('addresses'), 'Addresses');
    });
    test('uppercase single word', () {
      expect(formatParamsLabel('ADDRESSES'), 'Addresses');
    });
    test('Uppercase space separated string', () {
      expect(formatParamsLabel('ADDRESSES ARE HERE'), 'Addresses Are Here');
    });
    test('Uppercase multiple space separated string', () {
      expect(formatParamsLabel('ADDRESSES  ARE  HERE'), 'Addresses Are Here');
    });
    test('lowercase multiple words', () {
      expect(formatParamsLabel('addresses are here'), 'Addresses Are Here');
    });
    test('snake case multiple words', () {
      expect(formatParamsLabel('addresses_are_here'), 'Addresses Are Here');
    });
    test('lower camel case multiple words', () {
      expect(formatParamsLabel('addressesAreHere'), 'Addresses Are Here');
    });
    test('upper camel case multiple words', () {
      expect(formatParamsLabel('AddressesAreHere'), 'Addresses Are Here');
    });
  });
  group('formatParamsValue', () {
    test('should return the correct humanized summary for a map', () {
      expect(formatParamsValue('{}'), 'No items');
      expect(formatParamsValue('[]'), 'No items');
      expect(formatParamsValue('{"a": "b"}'), '1 item');
      expect(formatParamsValue('"{"a": "b"}"'), '1 item');
      expect(formatParamsValue('"{"a": "b", "c":"d"}"'), '2 items');
      expect(formatParamsValue('"{"a": "b", "c":"d", "z":"x"}"'), '3 items');
      expect(formatParamsValue('"[{"a": "b"},{"a": "b"}]"'), '2 items');
      expect(formatParamsValue('"Hello World"'), 'Hello World');
      expect(formatParamsValue('Hello World'), 'Hello World');
      expect(formatParamsValue('123'), '123');
      expect(formatParamsValue('NaN'), 'Not available');
      expect(formatParamsValue('null'), 'Not available');
      expect(formatParamsValue('true'), 'Yes');
      expect(formatParamsValue('false'), 'No');
      expect(formatParamsValue('0'), '0');
      expect(formatParamsValue('1'), '1');
      expect(formatParamsValue('2'), '2');
      expect(formatParamsValue('Infinity'), 'Infinite');
      expect(formatParamsValue('-Infinity'), 'Infinite');
      expect(formatParamsValue('1.23'), '1.23');
      // precision loss
      expect(formatParamsValue('1.2345678901234567890'), '1.2345678901234567');
      expect(formatParamsValue('[{"a": "b", "a": "c"}]'), '1 item');
      expect(formatParamsValue('[{"a": "b", "b": "c"}]'), '2 items');
    });
  });
}
