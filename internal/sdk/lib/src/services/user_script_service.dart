import 'dart:collection';
import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../data/providers.dart';
import '../logging/logging.dart';
import '../web_scripts/hawkeye/interception_method.dart';
import '../web_scripts/scripts/misc.dart';
import '../web_scripts/web_scripts.dart';
import '../webview_utils.dart';

class UserScriptService {
  static final logger = logging.child('UserScriptService');

  static Future<UnmodifiableListView<UserScript>> createUserScripts({
    required HttpProvider providerData,
    required Map<String, String> parameters,
    required int idleTimeThreshold,
    required HawkeyeInterceptionMethod hawkeyeInterceptionMethod,
  }) async {
    try {
      logger.info('Creating user scripts with provider: ${providerData.name}');
      final scripts = [
        UserScript(
          source: getProviderScriptEnvironment(providerData, parameters),
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
        UserScript(
          source: _createPayloadDataScript(providerData, parameters),
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
        UserScript(
          source: createInterceptorInjection(
            providerData,
            parameters,
            hawkeyeInterceptionMethod: hawkeyeInterceptionMethod,
          ),
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      ];

      // Add custom injection if available
      if (providerData.customInjection != null && providerData.customInjection!.isNotEmpty) {
        scripts.add(
          UserScript(source: providerData.customInjection!, injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START),
        );
      }

      // Add support for React Native custom injections
      scripts.add(
        UserScript(source: SUPPORT_RN_CUSTOM_INJECTIONS, injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START),
      );

      // Add user interaction injection
      scripts.add(
        UserScript(
          source: userInteractionInjection(idleTimeThreshold),
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      );

      // Add login button heuristics
      scripts.add(
        UserScript(source: loginButtonHeuristicsInjection(), injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START),
      );

      // Add HTML getter utility
      scripts.add(
        UserScript(
          source: "window.getHtml = () => document.documentElement.outerHTML;",
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      );

      logger.info('Successfully created ${scripts.length} user scripts');
      return UnmodifiableListView<UserScript>(scripts);
    } catch (e, s) {
      logger.severe('Error creating user scripts', e, s);
      rethrow;
    }
  }

  static String _createPayloadDataScript(HttpProvider? providerData, Map<String, String> parameters) {
    try {
      final payload = (providerData?.toJson() ?? <String, dynamic>{})
        ..remove('customInjection')
        ..addEntries([MapEntry('parameters', parameters)]);

      return '''
        try {
          window.payloadData = JSON.parse(String.raw`${jsonEncode(payload)}`);
          console.log('Payload data initialized:', window.payloadData);
        } catch (e) {
          console.error('Error initializing payload data:', e);
        }
      ''';
    } catch (e, s) {
      logger.severe('Error creating payload data script', e, s);
      rethrow;
    }
  }

  static String createInterceptorInjection(
    HttpProvider? providerData,
    Map<String, String> parameters, {
    required HawkeyeInterceptionMethod hawkeyeInterceptionMethod,
  }) {
    try {
      final injectionRequests = providerData?.requestData.map((e) {
        return InjectionRequest(
          urlRegex: convertTemplateToRegex(template: e.url ?? '', parameters: parameters, extraEscape: true).$1,
          bodySniffRegex: e.bodySniff?.enabled == true
              ? convertTemplateToRegex(template: e.bodySniff?.template ?? '', parameters: parameters).$1
              : "",
          bodySniffEnabled: e.bodySniff?.enabled == true,
          method: e.method!,
          requestHash: e.requestHash!,
        );
      });

      final injectionType = providerData?.injectionType;

      return createInjection(
        injectionRequests ?? const [],
        providerData?.disableRequestReplay ?? false,
        injectionType ?? InjectionType.MSWJS,
        hawkeyeInterceptionMethod: hawkeyeInterceptionMethod,
      );
    } catch (e, s) {
      logger.severe('Error creating intercepter injection', e, s);
      rethrow;
    }
  }

  static void extractUrlTemplateParams(
    dynamic proofData,
    Map<String, String> params,
    Map<String, String> initialParams,
  ) {
    try {
      final (urlRegex, _, urlParamKeys) = convertTemplateToRegex(
        template: proofData['matchedRequest'].url,
        parameters: initialParams,
      );

      final match = RegExp(urlRegex).firstMatch(proofData['url']);
      if (match == null) {
        logger.severe('No regex match found for URL extraction');
        return;
      }

      List<String?> urlParamValues = match.groups(List<int>.generate(urlParamKeys.length, (i) => i + 1)).toList();

      urlParamKeys.asMap().forEach((key, value) {
        final paramValue = urlParamValues[key];
        if (paramValue != null) {
          params[value] = paramValue;
        } else {
          logger.warning('Null parameter value found for key: $value');
        }
      });
    } catch (e, s) {
      logger.severe('Error extracting URL template params', e, s);
      rethrow;
    }
  }
}
