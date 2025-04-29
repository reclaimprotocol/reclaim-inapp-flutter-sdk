import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:reclaim_flutter_sdk/reclaim_flutter_sdk.dart';
import 'package:reclaim_flutter_sdk/logging/logging.dart';
import 'package:reclaim_flutter_sdk/types/manual_verification.dart';
import 'package:reclaim_flutter_sdk/utils/dio.dart';

class AIFlowService {
  final logger = logging.child('AIFlowService');
  final InAppWebViewController Function() _webView;
  final ValueChanged<String?>? recommendationSetter;
  final ValueChanged<bool> isLoggedInSetter;
  final VoidCallback showLoginToast;

  AIFlowService(this._webView, this.recommendationSetter, this.isLoggedInSetter, this.showLoginToast);

  InAppWebViewController get webView {
    return _webView();
  }

  Future<String> _detectLoginByCookies(String url, CookieManager cookieManager) async {
    final log = logger.child('detectLoginByCookies');
    final authCookiePatterns = [
      'auth',
      'session',
      'token',
      'logged',
      'user',
      'sid',
      'ssid',
      'uid',
      'account',
      'member',
      'jwt',
      'access_token',
      'id_token',
    ];
    String promptInput =
        "\nHere are the cookies that depending on our heuristics, we think are related to login. Please determine if the user is logged in or not. If the user is logged in, please return true, otherwise return false. If you are not sure, please return false.\n";
    try {
      final cookies = await cookieManager.getCookies(url: WebUri(url));

      for (var cookie in cookies) {
        final cookieName = cookie.name.toLowerCase();
        if (authCookiePatterns.any((pattern) => cookieName.contains(pattern))) {
          promptInput += "Cookie: ${cookie.name}\n";
        }
      }
      log.info('Prompt Input: $promptInput');
      return promptInput;
    } catch (e) {
      log.severe('Error detecting login by cookies', e);
      return "";
    }
  }

  Future<void> checkLoggedInState(String url, bool isLoggedIn, String? aiRecommendation, CookieManager cookieManager) async {
    final log = logger.child('checkLoggedInState');
    final promptInput = await _detectLoginByCookies(url, cookieManager);
    String heuristicSummary = await webView.evaluateJavascript(source: 'findLoginElements()');
    heuristicSummary += promptInput;
    log.info(heuristicSummary);

    final aiResult = await ReclaimSession.checkLoggedInStateWithAiV2(getAIFlowDioClient(), url, heuristicSummary);
    log.info(aiResult);

    if (aiResult['isLoggedIn']) {
      isLoggedInSetter(true);
      recommendationSetter!("You are logged in! Checking if data is shown...");
      log.info('Logged in Detected Successfully');
    } else {
      if (isLoggedIn) {
        isLoggedInSetter(false);
      }
      showLoginToast();
      log.info('Logged in Not Detected');
    }
  }

  Future<List<AIFlowDataReceipt>> extractData(String url, String sessionId) async {
    final log = logger.child('extractData');
    await Future.delayed(const Duration(seconds: 1));
    final html = await webView.evaluateJavascript(source: "window.getHtml()");
    final requiredFields = ["full_name", "field_of_study"];

    final response = await ReclaimSession.extractParamsFromHtml(getAIFlowDioClient(), url, html, requiredFields, sessionId);
    log.info(response);
    return response;
  }

  Dio getAIFlowDioClient() {
    return AIFlowDioClient.instance.dio;
  }

  void reset({bool onDispose = false}) {
    try {
      if (!onDispose) {
        recommendationSetter!(null);
      }
      AIFlowDioClient.instance.reset();
    } catch (e, s) {
      logger.child('reset').warning('Error during reset', e, s);
    }
  }

  Future<Uint8List?> captureScreenshot() async {
    try {
      final screenshot = await webView.takeScreenshot(screenshotConfiguration: ScreenshotConfiguration());
      return screenshot;
    } catch (e, s) {
      logger.child('captureScreenshot').warning('Error capturing screenshot', e, s);
      return null;
    }
  }


  Future<void> fallbackToManualVerification(
    CreateManualVerificationSessionPayload payload,
    String sessionId,
    List<RequestLog> requestLogs,
    String providerName,
    String providerId,
    Map<String, String> parameters
  ) async {
    final log = logger.child('fallbackToManualVerification');
    await ReclaimSession.createManualVerificationSession(payload);
    log.info('Manual verification session created');


    await ReclaimSession.dumpNetworkRequests(sessionId, requestLogs, providerName, providerId, parameters, '');
  }

  CreateClaimOutput createClaimOutputFromAIFlowDataReceipts(List<AIFlowDataReceipt> receipts) {
    final data = Map.fromEntries(receipts.where((e) => e.extractedValue != null).map((e) => MapEntry(e.name, e.extractedValue!)));
    return CreateClaimOutput(
      identifier: "0x586eba449fe949b73fc31d3c7723277930acb661404f216e8a6d5e6c5d403568",
      claimData: ProviderClaimData(
        provider: "http",
        parameters:
            "{\"additionalClientOptions\":{},\"body\":\"\",\"geoLocation\":\"\",\"headers\":{\"Sec-Fetch-Mode\":\"same-origin\",\"Sec-Fetch-Site\":\"same-origin\",\"User-Agent\":\"Mozilla/5.0\"},\"method\":\"GET\",\"paramValues\":{\"lang\":\"en\"},\"responseMatches\":[{\"invert\":false,\"type\":\"contains\",\"value\":\"lang=\\\"{{lang}}\\\"\"}],\"responseRedactions\":[{\"jsonPath\":\"\",\"regex\":\"lang=\\\"(.*?)\\\"\",\"xPath\":\"\"}],\"url\":\"https://github.com/settings/profile\"}",
        owner: "0xab65de9755adf80c343015fe7f28fb79690bba87",
        timestampS: 1739920373,
        context:
            "{\"contextAddress\":\"0x0\",\"contextMessage\":\"sample context\",\"extractedParameters\":{\"lang\":\"en\"},\"providerHash\":\"0xfcee42d80d1b1ed3109b369b8156f5083b62887129127a2a12799dd831461312\"}",
        identifier: "0x586eba449fe949b73fc31d3c7723277930acb661404f216e8a6d5e6c5d403568",
        epoch: 1,
      ),
      signatures: [
        "0x0be17b26946cfeb7bd556353ccd07022e70c9de9478c00361d00f2b991f4177c79e3ea17f9aad67e88feae24186830d4afa2dfcb6d05719b8f7e4bb9dcace0a91b",
      ],
      witnesses: [WitnessData(id: "0x244897572368eadf65bfbc5aec98d8e5443a9072", url: "wss://attestor.reclaimprotocol.org:447/ws")],
      publicData: data,
      providerRequest: null,
    );
  }
}

class AIFlowDataReceipt {
  final String name;
  final String? extractedValue;
  final String? recommendation;
  final String? actionUrl;

  AIFlowDataReceipt({required this.name, this.extractedValue, this.recommendation, this.actionUrl});

  factory AIFlowDataReceipt.fromJson(Map<String, dynamic> json) {
    return AIFlowDataReceipt(
      name: json['name'],
      extractedValue: json['extracted_value'],
      recommendation: json['recommendation'],
      actionUrl: json['actionUrl'],
    );
  }
}

class AIFlowDioClient {
  static AIFlowDioClient? _instance;
  Dio dio;

  AIFlowDioClient._internal() : dio = buildDio();

  static AIFlowDioClient get instance {
    _instance ??= AIFlowDioClient._internal();
    return _instance!;
  }

  void reset() {
    dio.close(force: true);
    dio = buildDio();
  }
}
