import '../logging/logging.dart';
import 'dio.dart';

bool isDynamicGeoLocation(
    String?
        providerGeoLocation) {
  return providerGeoLocation ==
          '{{DYNAMIC_GEO}}' ||
      providerGeoLocation ==
          '{{DYNAMIC_GEO_SECRET}}';
}

Future<String?>
    getUserLocation(
        String? providerGeoLocation) async {
  if (isDynamicGeoLocation(
      providerGeoLocation)) {
    return await getUserLocationBasedOnIp();
  } else {
    return providerGeoLocation;
  }
}

Future<String>
    getUserLocationBasedOnIp() async {
  final logger =
      logging.child('getUserLocation');
  try {
    final dio =
        buildDio();
    final response =
        await dio.get('https://ipapi.co/json/');
    if (response.statusCode ==
        200) {
      final data =
          response.data;
      final countryCode =
          data['country_code'];
      return countryCode;
    } else {
      logger.info('Error getting user location: ${response.statusCode}');
      // TODO: Add default geo location endpoint instead of hardcoding US
      return 'US';
    }
  } catch (e) {
    logger
        .info('Error getting user location: $e');
    return 'US';
  }
}
