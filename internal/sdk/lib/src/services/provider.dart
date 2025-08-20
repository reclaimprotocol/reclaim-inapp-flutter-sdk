import 'dart:convert';

import '../../reclaim_inapp_sdk.dart';
import '../constants.dart';
import '../logging/logging.dart';
import '../overrides/overrides.dart';
import 'base_http.dart';

class ReclaimProviderService {
  final logger = logging.child('ReclaimProviderService');

  Future<ReclaimDataProvidersResponse?> getProviders(
    String appId,
    String providerId,
    String sessionId,
    String signature,
    String timestamp, {
    required String resolvedVersion,
  }) async {
    final fetchProviderCallback = ReclaimOverrides.provider?.fetchProviderInformation;
    if (fetchProviderCallback != null) {
      final provider = await fetchProviderCallback(
        appId: appId,
        providerId: providerId,
        sessionId: sessionId,
        signature: signature,
        timestamp: timestamp,
        resolvedVersion: resolvedVersion,
      );
      return ReclaimDataProvidersResponse(
        isSucces: true,
        providers: ReclaimDataProviders(appId: appId, httpProvider: [provider]),
      );
    }

    final client = reclaimHttpBaseClient;

    final response = await client.post(
      Uri.parse(
        ReclaimUrls.getApplicationProviderUrl(appId, providerId),
      ).replace(queryParameters: {'versionNumber': resolvedVersion}),
      headers: {'accept': '*/*', 'accept-language': 'en-GB,en-US;q=0.9,en;q=0.8', 'Content-Type': 'application/json'},
      body: json.encode({'signature': signature, 'timestamp': timestamp}),
    );

    if (response.isSuccess) {
      final data = response.bodyAsJson;
      if (data != null) {
        return ReclaimDataProvidersResponse.fromJson(data);
      }
    }
    logger.severe('Failed to fetch provider information: ${response.body}', response.statusCode);
    return null;
  }
}
