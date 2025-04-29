import 'dart:convert';

import '../data/providers.dart';
import '../overrides/overrides.dart';

import 'base_http.dart';

class ReclaimProviderService {
  Future<ReclaimDataProvidersResponse?>
      getProviders(
    String
        appId,
    String
        providerId,
    String
        sessionId,
    String
        signature,
    String
        timestamp,
  ) async {
    final fetchProviderCallback = ReclaimOverrides
        .provider
        ?.fetchProviderInformation;
    if (fetchProviderCallback !=
        null) {
      final provider =
          await fetchProviderCallback(
        appId: appId,
        providerId: providerId,
        sessionId: sessionId,
        signature: signature,
        timestamp: timestamp,
      );
      return ReclaimDataProvidersResponse(
        isSucces: true,
        providers: ReclaimDataProviders(
          appId: appId,
          httpProvider: [
            provider
          ],
        ),
      );
    }

    final client =
        reclaimHttpBaseClient;
    client
        .options
        .headers['accept'] = '*/*';
    client
        .options
        .headers['accept-language'] = 'en-GB,en-US;q=0.9,en;q=0.8';
    client
        .options
        .headers['Content-Type'] = 'application/json';

    final response =
        await client.post<String>(
      '/applications/$appId/provider//$providerId',
      data:
          json.encode({
        'signature': signature,
        'timestamp': timestamp,
      }),
    );

    final statusCode =
        response.statusCode;
    if (statusCode != null &&
        statusCode >= 200 &&
        statusCode < 300) {
      final data =
          response.data;
      if (data !=
          null) {
        return ReclaimDataProvidersResponse.fromJson(json.decode(data));
      }
    }
    return null;
  }
}
