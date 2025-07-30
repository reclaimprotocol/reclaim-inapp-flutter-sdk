import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_inapp_sdk/src/utils/user_agent.dart';

void main() {
  test('test user agent', () {
    final userAgent = WebViewUserAgentUtil.generateChromeAndroidUserAgent(chromeMajorVersion: 136, isMobile: true);
    expect(
      userAgent,
      'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Mobile Safari/537.36',
    );
  });
}
