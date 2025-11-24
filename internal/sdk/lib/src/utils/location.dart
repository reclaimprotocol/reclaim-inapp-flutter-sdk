import '../logging/logging.dart';
import 'http/http.dart';

bool isDynamicGeoLocation(String? providerGeoLocation) {
  return providerGeoLocation == '{{DYNAMIC_GEO}}' || providerGeoLocation == '{{DYNAMIC_GEO_SECRET}}';
}

Future<String?> getUserLocation(String? providerGeoLocation) async {
  final logger = logging.child('getUserLocation');
  try {
    if (isDynamicGeoLocation(providerGeoLocation)) {
      return await getUserLocationBasedOnIp();
    } else {
      return providerGeoLocation;
    }
  } catch (e, s) {
    logger.severe('failed', e, s);
    return null;
  }
}

final _client = ReclaimHttpClient();

Future<String> getUserLocationBasedOnIp() async {
  final logger = logging.child('getUserLocation');
  const defaultLocation = 'US';
  try {
    final response = await _client.get(Uri.parse('https://ipapi.co/json/')).timeout(const Duration(seconds: 8));
    if (response.isSuccess) {
      final countryCode = response.bodyAsJson?['country_code'];
      return countryCode ?? defaultLocation;
    } else {
      logger.info('Error getting user location: ${response.statusCode}');
      // TODO: Add default geo location endpoint instead of hardcoding US
      return defaultLocation;
    }
  } catch (e, s) {
    logger.info('Error getting user location', e, s);
    return defaultLocation;
  }
}
