import 'dart:convert';

import '../../attestor.dart';
import '../../data/providers.dart';
import '../../logging/logging.dart';
import '../../types/create_claim.dart';
import '../../utils/location.dart';
import '../../utils/strings.dart';
import '../../utils/url.dart'
    as url_utils;
import '../../webview_utils.dart';

class ClaimCreationRequest {
  final String
      appId;
  final String
      claimContext;
  final String
      sessionId;
  final String
      privateKey;
  final Map<
      String,
      String> initialWitnessParams;
  final Map<
      String,
      String> witnessParams;
  final HttpProvider
      providerData;
  final bool
      useSingleRequest;
  final ExtractedData
      extractedData;
  final AttestorClaimOptions
      createClaimOptions;
  final DataProviderRequest
      requestData;

  String
      get hostUrl {
    String
        url =
        url_utils.extractHost(extractedData.url);
    final params =
        extractedData.witnessParams;
    return interpolateParamsInTemplate(
        url,
        params);
  }

  ClaimCreationRequest._({
    required this.appId,
    required this.claimContext,
    required this.sessionId,
    required this.privateKey,
    required this.providerData,
    required this.initialWitnessParams,
    required this.witnessParams,
    required this.useSingleRequest,
    required this.extractedData,
    required this.createClaimOptions,
    required this.requestData,
  });

  Map<String,
          dynamic>
      get additionalClientOptions {
    return providerData.additionalClientOptions ??
        const {};
  }

  Map<String, dynamic> get httpParams => _getHttpParams(
      extractedData,
      additionalClientOptions);

  Map<String,
          dynamic>
      get secretParams =>
          _getSecretParams(extractedData);

  String get httpProviderId =>
      providerData.httpProviderId ??
      '';

  factory ClaimCreationRequest({
    required String
        appId,
    required String
        claimContext,
    required String
        sessionId,
    required String
        privateKey,
    required dynamic
        proofData,
    required HttpProvider
        providerData,
    required Map<String, String>
        headers,
    required Map<String, String>
        initialWitnessParams,
    required String
        cookieString,
    required AttestorClaimOptions
        createClaimOptions,
    required bool
        useSingleRequest,
    required DataProviderRequest
        requestData,
    String?
        geoLocation,
    bool isRequestFromProviderScript =
        false,
  }) {
    final logger =
        logging.child(
      'ClaimCreationRequest.${requestData.requestIdentifier}',
    );

    final String providerUrl = requestData.urlType == UrlType.TEMPLATE
        ? (requestData.url ?? '')
        : proofData['url'];

    logger
        .info({
      'provider_url_type':
          requestData.urlType,
      'provider_url':
          providerUrl,
    });

    final Map<String, String>
        witnessParams =
        {};
    if (requestData.urlType ==
        UrlType.TEMPLATE) {
      extractUrlTemplateParams(
        requestData,
        proofData,
        initialWitnessParams,
        witnessParams,
      );
    }

    logger
        .info({
      'bodySniff':
          requestData.bodySniff != null,
      'bodySniff.template':
          requestData.bodySniff?.template != null,
    });

    if (requestData.bodySniff?.enabled == true &&
        requestData.bodySniff?.template?.isNotEmpty == true) {
      extractRequestBodyTemplateParams(
        requestData,
        proofData,
        initialWitnessParams,
        witnessParams,
      );
    }

    return ClaimCreationRequest
        ._(
      appId:
          appId,
      claimContext:
          claimContext,
      sessionId:
          sessionId,
      privateKey:
          privateKey,
      providerData:
          providerData,
      initialWitnessParams:
          initialWitnessParams,
      witnessParams: {
        ...witnessParams,
        if (geoLocation != null && isDynamicGeoLocation(providerData.geoLocation))
          '${providerData.geoLocation?.replaceAll('{', '').replaceAll('}', '')}': geoLocation,
      },
      createClaimOptions:
          createClaimOptions,
      useSingleRequest:
          useSingleRequest,
      requestData:
          requestData,
      extractedData:
          ExtractedData(
        geoLocation: providerData.geoLocation,
        url: providerUrl,
        headers: headers,
        cookies: cookieString,
        requestBody: (isRequestFromProviderScript ? proofData['requestBody'] : (requestData.bodySniff?.template ?? proofData['requestBody'])) ?? '',
        method: requestData.method?.name ?? '',
        witnessParams: {
          ...witnessParams,
          ...initialWitnessParams,
          if (geoLocation != null && isDynamicGeoLocation(providerData.geoLocation)) '${providerData.geoLocation?.replaceAll('{', '').replaceAll('}', '')}': geoLocation,
        },
        // These will be provided to the Witness SDK by the witness webview
        // through RPC. Below values are placeholders.
        responseRedactions: requestData.responseRedactions ?? const [],
        responseMatches: requestData.responseMatches ?? const [],
      ),
    );
  }

  ClaimCreationRequest
      copyWith({
    String?
        appId,
    String?
        claimContext,
    String?
        sessionId,
    String?
        privateKey,
    HttpProvider?
        providerData,
    Map<String, String>?
        witnessParams,
    Map<String, String>?
        initialWitnessParams,
    bool?
        useSingleRequest,
    DataProviderRequest?
        requestData,
    ExtractedData?
        extractedData,
    AttestorClaimOptions?
        createClaimOptions,
  }) {
    return ClaimCreationRequest
        ._(
      appId:
          appId ?? this.appId,
      claimContext:
          claimContext ?? this.claimContext,
      sessionId:
          sessionId ?? this.sessionId,
      privateKey:
          privateKey ?? this.privateKey,
      providerData:
          providerData ?? this.providerData,
      witnessParams:
          witnessParams ?? this.witnessParams,
      initialWitnessParams:
          initialWitnessParams ?? this.initialWitnessParams,
      useSingleRequest:
          useSingleRequest ?? this.useSingleRequest,
      requestData:
          requestData ?? this.requestData,
      extractedData:
          extractedData ?? this.extractedData,
      createClaimOptions:
          createClaimOptions ?? this.createClaimOptions,
    );
  }

  static Map<
      String,
      String> extractUrlTemplateParams(
    DataProviderRequest
        dataRequest,
    Map proofData,
    Map<String, String>
        initialWitnessParams,
    final Map<String, String>
        params,
  ) {
    final logger =
        logging.child('extractUrlTemplateParams');
    final (
      urlRegex,
      _,
      urlParamKeys
    ) = convertTemplateToRegex(
      template:
          dataRequest.url ?? '',
      parameters:
          initialWitnessParams,
    );

    final urlMatch =
        RegExp(urlRegex).firstMatch(proofData['url']);
    if (urlMatch ==
        null) {
      logger.info(
        json.encode({
          'reason': 'No matches for regex',
          'url': proofData['url'],
          'datarequesturl': dataRequest.url,
          'urlRegex': urlRegex,
        }),
      );
    }
    final List<String?>
        urlParamValues =
        urlMatch?.groups(List<int>.generate(urlParamKeys.length, (i) => i + 1)).toList() ?? [];
    urlParamKeys
        .asMap()
        .forEach((key, value) {
      params[value] =
          urlParamValues[key]!;
    });
    return params;
  }

  static Map<
      String,
      String> extractRequestBodyTemplateParams(
    DataProviderRequest
        dataRequest,
    Map proofData,
    Map<String, String>
        initialWitnessParams,
    final Map<String, String>
        params,
  ) {
    String
        requestTemplate =
        dataRequest.bodySniff?.template ?? '';
    var (
      requestBodyRegex,
      _,
      requestBodyParamKeys
    ) = convertTemplateToRegex(
      template:
          requestTemplate,
      parameters:
          initialWitnessParams,
    );
    List<String?> requestBodyParamValues = RegExp(requestBodyRegex)
        .firstMatch(proofData['requestBody'])!
        .groups(
          List<int>.generate(requestBodyParamKeys.length, (i) => i + 1),
        )
        .toList();
    requestBodyParamKeys
        .asMap()
        .forEach((key, value) {
      params[value] =
          requestBodyParamValues[key]!;
    });
    return params;
  }
}

const _PUBLIC_HEADERS_ALLOW_LIST =
    [
  "user-agent",
  "accept",
  "accept-language",
  "accept-encoding",
  "sec-fetch-mode",
  "sec-fetch-site",
  "sec-fetch-user",
  "origin",
  "x-requested-with",
  "sec-ch-ua",
  "sec-ch-ua-mobile",
];

Map<String,
        dynamic>
    _getHttpParams(
  ExtractedData
      data,
  Map<String,
          dynamic>
      additionalClientOptions,
) {
  Map<String,
          String>
      publicWitnessParams =
      {};
  data.witnessParams.forEach((key,
      value) {
    if (!key
        .contains('SECRET')) {
      publicWitnessParams[key] =
          value;
    }
  });
  final logger =
      logging.child('_getHttpParams');
  Map<String,
          String>
      publicHeaders =
      {};
  for (final key in data
      .headers
      .keys) {
    _PUBLIC_HEADERS_ALLOW_LIST.contains(key.toLowerCase())
        ? publicHeaders[key] = data.headers[key] ?? ""
        : null;
  }

  logger.info(
      'publicHeaders: $publicHeaders');
  return {
    'geoLocation':
        data.geoLocation,
    'url':
        data.url,
    'method':
        data.method,
    'body':
        data.requestBody,
    'headers':
        publicHeaders,
    'responseMatches': data
        .responseMatches
        .map((e) => e.toJson())
        .toList(),
    'responseRedactions': data
        .responseRedactions
        .map((e) => e.toJson())
        .toList(),
    'paramValues':
        publicWitnessParams,
    'additionalClientOptions':
        additionalClientOptions,
  };
}

Map<String,
        dynamic>
    _getSecretParams(
        ExtractedData data) {
  Map<String,
          String>
      privateWitnessParams =
      {};
  data.witnessParams.forEach((key,
      value) {
    if (key
        .contains('SECRET')) {
      privateWitnessParams[key] =
          value;
    }
  });
  Map<String,
          String>
      privateHeaders =
      {};
  for (var key in data
      .headers
      .keys) {
    !_PUBLIC_HEADERS_ALLOW_LIST.contains(key.toLowerCase())
        ? privateHeaders[key] = data.headers[key] ?? ""
        : null;
  }

  return {
    'headers':
        privateHeaders,
    'cookieStr':
        data.cookies,
    'paramValues':
        privateWitnessParams,
  };
}
