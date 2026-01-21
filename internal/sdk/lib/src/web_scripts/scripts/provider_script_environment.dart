import 'dart:convert';

import '../../data/providers.dart';

String _objectToJsObject(Object object) {
  final jsonEncodedObject = json.encode(object);
  final jsonString = json.encode(jsonEncodedObject);
  return 'JSON.parse($jsonString)';
}

String getProviderScriptEnvironment(HttpProvider providerData, Map<String, String> parameters) {
  final providerJsObject = _objectToJsObject(providerData.toJson()..remove('customInjection'));

  return """
addEventListener("DOMContentLoaded", (event) => {
  const preNode = document.evaluate(
    '//pre',
    document,
    null,
    XPathResult.FIRST_ORDERED_NODE_TYPE,
    null,
  ).singleNodeValue;
  const preText = preNode ? preNode.innerText : null;
  if (preText) {
    window._ResponseOnDocumentContentLoaded = preText;
  } else {
    window._ResponseOnDocumentContentLoaded = document.documentElement.innerHTML;
  }
  if (typeof window._On_ResponseOnDocumentContentLoaded === 'function') {
    window._On_ResponseOnDocumentContentLoaded(location.href, document.contentType, window._ResponseOnDocumentContentLoaded);
  }
}, {once: true});

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
    requiresUserInteraction: (isUserInteractionRequired) => {
        window.ReclaimMessenger.send('requiresUserInteraction', { value: !!isUserInteractionRequired });
    },
    setAllowedAppLinks: (allowedAppLinks) => {
      if (typeof allowedAppLinks !== 'string' && allowedAppLinks !== null && allowedAppLinks !== undefined) {
          console.warn('Unknown type of arg', typeof allowedAppLinks);
      }
      window.ReclaimMessenger.send('setAllowedAppLinks', { value: allowedAppLinks });
    },
    updateUserAgent: (userAgent) => {
      if (typeof userAgent !== 'string' && userAgent !== null && userAgent !== undefined) {
          console.warn('Unknown type of arg', typeof userAgent);
      }
      window.ReclaimMessenger.send('updateUserAgent', { value: userAgent });
    },
    canExpectManyClaims: (canExpectManyClaims) => {
        window.ReclaimMessenger.send('canExpectManyClaims', { value: !!canExpectManyClaims });
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
    // log(logType: 'error' | 'info', message: object)
    log: (logType, message) => {
        window.ReclaimMessenger.log(logType, message);
    },
}

""";
}
