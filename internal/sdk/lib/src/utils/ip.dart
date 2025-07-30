import '../logging/logging.dart';
import 'http/http.dart';

final _client = ReclaimHttpClient();

Future<String> getPublicIp() async {
  final log = logging.child('getPublicIp');
  try {
    final response = await _client.get(Uri.parse('https://api.ipify.org?format=json')).timeout(Duration(seconds: 5));
    if (response.isSuccess) {
      final ip = response.bodyAsJson?['ip'];
      if (ip is String && ip.isNotEmpty) return ip;
    }
    log.warning({'reason': 'Failed to get public IP address', 'response.data': response.body});
  } catch (e, s) {
    log.warning('Failed to get public IP address. Returning 0.0.0.0.', e, s);
  }
  return '0.0.0.0';
}
