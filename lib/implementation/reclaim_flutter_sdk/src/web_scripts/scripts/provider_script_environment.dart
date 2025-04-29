import 'dart:convert';

import '../../../data/providers.dart';

String _objectToJsObject(
    Object
        object) {
  final jsonEncodedObject =
      json.encode(object);
  final jsonString =
      json.encode(jsonEncodedObject);
  return 'JSON.parse($jsonString)';
}

String
    getProviderScriptEnvironment(
  HttpProvider
      providerData,
  Map<String,
          String>
      parameters,
) {
  final providerJsObject =
      _objectToJsObject(
    providerData
        .toJson()
      ..remove('customInjection'),
  );

  return """
window.ReclaimMessenger = {
    _send: (event, message) => {
        if ('flutter_inappwebview' in window) {
            let e = window.flutter_inappwebview;
            if ('callHandler' in e) {
                e.callHandler(event, JSON.stringify(message));
                return true;
            }
        }
        return false;
    },
    log: (logType, message) => {
        switch (logType) {
            case 'error':
                if (window.ReclaimMessenger._send('errorLogs', message)) return;
                console.error(message);
                break;
            default:
                if (window.ReclaimMessenger._send('debugLogs', message)) return;
                console.log(message);
                break;
        }
    },
    send: (event, message) => {
        if (window.ReclaimMessenger._send(event, message)) {
            return;
        }

        window.ReclaimMessenger.log('error', { reason: `failed to send message, unknown environment`, event, message });
    }
}

window.Reclaim = {
    version: 1,
    provider: $providerJsObject,
    parameters: ${_objectToJsObject(parameters)},
    requestClaim: (claim) => {
        window.ReclaimMessenger.send('extractedData', claim);
    },
    canExpectManyClaims: (canExpectManyClaims) => {
        window.ReclaimMessenger.send('canExpectManyClaims', { value: canExpectManyClaims });
    },
    updatePublicData: (data) => {
        window.ReclaimMessenger.send('publicData', data);
    },
    reportProviderError: (error) => {
        if (typeof error === 'string') {
            error = { message: error };
        }
        window.ReclaimMessenger.send('reportProviderError', error);
    },
}

""";
}
