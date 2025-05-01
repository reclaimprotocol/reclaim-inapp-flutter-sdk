import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_flutter_sdk/widgets/params/string.dart';

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
}
