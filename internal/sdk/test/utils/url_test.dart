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

  group('url equal', () {
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

  group('isUrlAllowedToLaunch', () {
    test('should return the true from a valid url', () {
      expect(isUrlAllowedToLaunch(Uri.parse('https://example.com/login'), 'https://example.com/login'), isTrue);
      expect(isUrlAllowedToLaunch(Uri.parse('hello://example.com/login'), '*'), isTrue);
      const urls = [
        'com-okta-authenticator:',
        'https://login.okta.com/auth/okta-verify',
        'https://login.okta.com/azt/install-android-device-policy',
        'https://login.okta.com/oauth/callback',
        'https://login.okta.com/oauth/callback',
        'https://login.okta.com/actions/enroll',
        'oktaverify',
      ];
      for (final url in urls) {
        expect(
          isUrlAllowedToLaunch(
            Uri.parse(url),
            r'^(com-okta-authenticator:|https:\/\/login\.okta\.com\/auth\/okta-verify|https:\/\/login\.okta\.com\/azt\/install-android-device-policy|https:\/\/login\.okta\.com\/oauth\/callback|https:\/\/login\.okta\.com\/actions\/enroll|oktaverify)',
          ),
          isTrue,
          reason: 'Did not match with $url',
        );
      }
    });
    test('should return the false from a url with no match', () {
      expect(isUrlAllowedToLaunch(Uri.parse('https://example.com'), 'https://example.com/login'), isFalse);
      expect(isUrlAllowedToLaunch(Uri.parse('https://example.com/login'), '*'), isFalse);
      const urls = [
        'reclaimbank:',
        'https://login.example.com/auth/okta-verify',
        'https://login.example.com/azt/install-android-device-policy',
        'https://google.com/oauth/callback',
        'https://example.org/oauth/callback',
        'googleverify',
      ];
      for (final url in urls) {
        expect(
          isUrlAllowedToLaunch(
            Uri.parse(url),
            r'^(com-okta-authenticator:|https:\/\/login\.okta\.com\/auth\/okta-verify|https:\/\/login\.okta\.com\/azt\/install-android-device-policy|https:\/\/login\.okta\.com\/oauth\/callback|https:\/\/login\.okta\.com\/actions\/enroll|oktaverify)',
          ),
          isFalse,
          reason: 'Did match with $url',
        );
      }
    });
  });
}
