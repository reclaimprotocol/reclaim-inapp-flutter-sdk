import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_flutter_sdk/utils/url.dart';

void main() {
  group('extractHost', () {
    test('should return the host of the url (without www)', () {
      expect(extractHost('https://www.example.com/dashboard'), 'example.com');
      expect(extractHost('https://admin.example.com/dashboard'),
          'admin.example.com');
    });
  });

  group('createRefererUrl', () {
    test('should return the referer url', () {
      expect(
        createRefererUrl(
            'https://user:password@example.com/page.html?foo=bar#hello'),
        'https://example.com/page.html?foo=bar',
      );
    });
  });
}
