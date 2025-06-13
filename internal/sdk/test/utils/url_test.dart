import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_inapp_sdk/src/utils/url.dart';

void main() {
  group('extractHost', () {
    test('should return the host of the url (without www)', () {
      expect(extractHost('https://www.example.com/dashboard'), 'example.com');
      expect(extractHost('https://admin.example.com/dashboard'), 'admin.example.com');
    });
  });

  group('createRefererUrl', () {
    test('should return the referer url', () {
      expect(
        createRefererUrl('https://user:password@example.com/page.html?foo=bar#hello'),
        'https://example.com/page.html?foo=bar',
      );
    });
  });

  group('login url and url equal', () {
    test('should return true if the login url is null and the url is a login url', () {
      expect(isLoginUrl('https://example.com/login'), true);
      expect(isLoginUrl('https://github.com/settings/profile'), false);
      expect(isLoginUrl('https://github.com/login?return_to=https%3A%2F%2Fgithub.com%2Fsettings%2Fprofile'), true);
      expect(isLoginUrl('https://x.com/?logout=1748851281882'), true);
      expect(
        isLoginUrl('https://my.dmv.ca.gov/mga/sps/authsvc?TransactionId=3c5e133f-c2d5-4553-bcff-eed0f12ecbbc'),
        true,
      );
    });
    test('should return true if the urls are equal', () {
      expect(isUrlsEqual('https://example.com/login', 'https://example.com/login?foo=bar'), true);
      expect(isUrlsEqual('https://github.com/settings/profile', 'https://github.com/settings/profile'), true);
      expect(
        isUrlsEqual(
          'https://github.com/settings/profile',
          'https://github.com/settings/profile?return_to=https%3A%2F%2Fgithub.com%2Fsettings%2Fprofile',
        ),
        true,
      );
      expect(
        isUrlsEqual(
          'https://github.com/settings/profile',
          'https://github.com/login?return_to=https%3A%2F%2Fgithub.com%2Fsettings%2Fprofile',
        ),
        false,
      );
    });
  });

  group('createUrlFromLocation', () {
    test('should return the full url from a relative url', () {
      expect(createUrlFromLocation('/login', 'https://example.com'), 'https://example.com/login');
      expect(createUrlFromLocation('/login', 'https://example.com/'), 'https://example.com/login');
      expect(createUrlFromLocation('/login', 'https://example.com/dashboard'), 'https://example.com/login');
      expect(createUrlFromLocation('example.org/login', 'https://example.com/dashboard'), 'https://example.org/login');
      expect(
        createUrlFromLocation('http://example.org/login', 'https://example.com/dashboard'),
        'http://example.org/login',
      );
      expect(
        createUrlFromLocation('https://example.org/login', 'https://example.com/dashboard'),
        'https://example.org/login',
      );
    });
  });
}
