import '../logging/logging.dart';
import 'dio.dart';

Future<String>
    getPublicIp() async {
  final log =
      logging.child('getPublicIp');
  try {
    final dio =
        buildDio();
    final response =
        await dio.get<Map<String, dynamic>>('https://api.ipify.org?format=json');
    if (response.statusCode ==
        200) {
      final ip =
          response.data?['ip'];
      if (ip is String &&
          ip.isNotEmpty)
        return ip;
    }
    log.warning({
      'reason':
          'Failed to get public IP address',
      'response.data':
          response.data,
    });
  } catch (e, s) {
    log.severe(
        'Failed to get public IP address',
        e,
        s);
  }
  return '0.0.0.0';
}
