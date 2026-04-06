import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_inapp_sdk/src/utils/sanitize.dart';

void main() {
  group('sanitize', () {
    test('ensureMap', () {
      expect(ensureMap<String, String>({'a': 'b'}), const <String, String>{'a': 'b'});
      expect(ensureMap<String, String>({'a': 'b', 'c': 'd'}), const <String, String>{'a': 'b', 'c': 'd'});
      expect(ensureMap<String, String>({'a': 'b', 'c': 'd'}), const <String, String>{'a': 'b', 'c': 'd'});
    });
  });

  group('sanitizeLogMessage', () {
    test('returns empty string unchanged', () {
      expect(sanitizeLogMessage(''), '');
    });

    test('passes through string with no sensitive data', () {
      const input = 'INFO: Request completed successfully in 42ms';
      expect(sanitizeLogMessage(input), input);
    });

    test('redacts single-value Cookie header', () {
      const input = 'Cookie: session=abc123';
      expect(sanitizeLogMessage(input), 'Cookie: [REDACTED]');
    });

    test('redacts multi-value Cookie header (entire line)', () {
      const input = 'Cookie: session=abc123; auth=secret456; tracking_id=789';
      expect(sanitizeLogMessage(input), 'Cookie: [REDACTED]');
    });

    test('redacts Set-Cookie header (value only, preserves attributes)', () {
      const input = 'Set-Cookie: session=abc123; Path=/; HttpOnly';
      expect(sanitizeLogMessage(input), 'Set-Cookie: [REDACTED]; Path=/; HttpOnly');
    });

    test('redacts Authorization header', () {
      const input = 'authorization: Basic dXNlcjpwYXNz';
      expect(sanitizeLogMessage(input), 'authorization: [REDACTED]');
    });

    test('redacts Bearer token', () {
      const input = 'Bearer eyJhbGciOiJIUzI1NiJ9.test.sig';
      expect(sanitizeLogMessage(input), 'Bearer [REDACTED]');
    });

    test('redacts JWT token', () {
      const input =
          'Found token eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U in response';
      final result = sanitizeLogMessage(input);
      expect(result, contains('[REDACTED]'));
      expect(result, isNot(contains('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9')));
    });

    test('redacts generic secret/password/token fields', () {
      expect(sanitizeLogMessage('secret=mysecretvalue'), 'secret=[REDACTED]');
      expect(sanitizeLogMessage('password: hunter2'), 'password: [REDACTED]');
      expect(sanitizeLogMessage('token=abc123def'), 'token=[REDACTED]');
      expect(sanitizeLogMessage('api_key: sk-12345'), 'api_key: [REDACTED]');
      expect(sanitizeLogMessage('client_secret=xyzzy'), 'client_secret=[REDACTED]');
    });

    test('redacts proof and proofString fields', () {
      expect(sanitizeLogMessage('proof: 0xdeadbeef'), 'proof: [REDACTED]');
      expect(sanitizeLogMessage('proofString=longbase64data'), 'proofString=[REDACTED]');
    });

    test('redacts requestBody/responseBody/payload/body fields', () {
      expect(sanitizeLogMessage('requestBody: {"user":"test"}'), 'requestBody: [REDACTED]');
      expect(sanitizeLogMessage('responseBody=encrypted_data'), 'responseBody=[REDACTED]');
      expect(sanitizeLogMessage('payload: sensitive_content'), 'payload: [REDACTED]');
      expect(sanitizeLogMessage('body: raw_data'), 'body: [REDACTED]');
    });

    test('redacts email addresses', () {
      const input = 'User logged in: user@example.com from 192.168.1.1';
      final result = sanitizeLogMessage(input);
      expect(result, contains('[REDACTED]'));
      expect(result, isNot(contains('user@example.com')));
    });

    test('redacts PEM private key', () {
      const input = 'Key found: -----BEGIN PRIVATE KEY-----\nMIIBVAIBADANBg\n-----END PRIVATE KEY-----';
      final result = sanitizeLogMessage(input);
      expect(result, isNot(contains('MIIBVAIBADANBg')));
      expect(result, contains('[REDACTED]'));
    });

    test('redacts multiple sensitive patterns in one string', () {
      const input = 'Cookie: session=abc; Authorization: Bearer tk_123; user@test.com sent password=hunter2';
      final result = sanitizeLogMessage(input);
      expect(result, isNot(contains('session=abc')));
      expect(result, isNot(contains('tk_123')));
      expect(result, isNot(contains('user@test.com')));
      expect(result, isNot(contains('hunter2')));
    });
  });
}
