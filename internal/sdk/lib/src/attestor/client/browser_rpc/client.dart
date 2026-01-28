import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'
    show
        HeadlessInAppWebView,
        InAppWebViewSettings,
        RendererPriority,
        RendererPriorityPolicy,
        URLRequest,
        UserScript,
        UserScriptInjectionTime,
        WebUri;
import 'package:reclaim_tee_operator_flutter/reclaim_tee_operator_flutter.dart';
import 'package:retry/retry.dart';

import '../../../../logging.dart';
import '../base.dart';
import '../client_operator.dart';

/// An attestor client that uses webview with attestor browser rpc
class AttestorWebViewClient extends AttestorJsClient with AttestorClientOperator {
  final Uri attestorBrowserRpcUrl;
  final StreamController<bool> _isInspectableStreamController;

  AttestorWebViewClient({
    required this.attestorBrowserRpcUrl,
    required super.debugLabel,
    bool isInspectable = kDebugMode,
  }) : _isInspectableStreamController = StreamController.broadcast()..add(isInspectable) {
    _buildWebViewForAttestor(isInspectable: isInspectable);
  }

  /// Post a message to the attestor client's browser rpc handler
  @override
  Future<void> postMessage(RpcMessage rpcMessage) async {
    final log = logger.child('AttestorWebViewClient.postMessage');

    try {
      final message = json.encode(rpcMessage);

      // using json.encode here to string escape the json message correctly
      final js =
          'globalThis.ATTESTOR_BASE_URL = "${attestorBrowserRpcUrl.origin}";globalThis.RPC_CHANNEL_NAME = "${AttestorJsClient.hostMessengerChannelName}";window.HostMessenger = window.backupMessenger;window.postMessage(${json.encode(message)});';

      await retry(
        () => executeJavascript(js, debugId: rpcMessage.id),
        retryIf: (e) => e is AttestorClientNotReadyException,
      );
    } catch (e, s) {
      log.severe('Error sending request', e, s);
    }
  }

  Future<Object?> executeJavascript(String js, {String? debugId}) async {
    final log = logger.child('AttestorWebViewClient.executeJavascript');

    log.debug({'tag': 'rpc.js', 'value': js, if (debugId != null) 'debugId': debugId});

    final controller = _innerWebView.webViewController;
    await _ensureReadiness();
    if (controller == null) {
      throw const AttestorClientInitializationException('Webview controller is null');
    }

    return () async {
      try {
        final response = await controller.evaluateJavascript(source: js);
        log.finest({'tag': 'rpc.js.response', 'value': response, if (debugId != null) 'debugId': debugId});

        return response;
      } catch (e, s) {
        log.severe('Error evaluating javascript for debugId $debugId', e, s);
        rethrow;
      }
    }();
  }

  Future<void> _ensureReadiness() async {
    final log = logger.child('AttestorWebViewClient._ensureReadiness');

    final controller = _innerWebView.webViewController;

    Future<bool> evaluateIsWebviewReady() async {
      await ensureReady().timeout(const Duration(seconds: 5));
      if (controller == null) {
        throw const AttestorClientInitializationException('Webview controller is null');
      }
      final response = await controller
          .evaluateJavascript(source: '(() => { return 0 + 1; })()')
          .timeout(const Duration(seconds: 5));
      return response == 1 || response.toString() == '1';
    }

    await retry(
      () async {
        if (!await evaluateIsWebviewReady()) {
          throw const AttestorClientInitializationException('Attestor webview did not respond to liveliness check');
        } else {
          log.info('Webview is ready');
        }
      },
      retryIf: (e) {
        log.severe('Retrying webview readiness check', e);
        return e is AttestorClientNotReadyException || e is TimeoutException;
      },
    );
  }

  void _handleHostRpcMessage(List<dynamic> args) async {
    final log = logger.child('AttestorWebViewClient.handleHostRpcMessage');
    log.finest({'tag': 'rpc.message', if (args.isNotEmpty) 'value': args[0]});

    try {
      return await handleIncomingMessage(args[0]);
    } catch (e, s) {
      log.severe('Error handling error for rpc message $args', e, s);
    }
  }

  @override
  Future<void> dispose() async {
    final log = logger.child('AttestorWebViewClient.dispose');

    try {
      for (final subscription in _subscriptions) {
        subscription.cancel();
      }
      _subscriptions.clear();
      await _innerWebView.dispose();
    } catch (e, s) {
      log.warning('Error disposing webview', e, s);
    }

    _isInspectableStreamController.close();
    _loadingProgressNotifier.dispose();
    if (!_webviewLoadCompleter.isCompleted) {
      _webviewLoadCompleter.completeError(Exception('_innerWebView disposed before initialization completed'));
    }

    super.dispose();
  }

  late var _webviewLoadCompleter = Completer<void>();

  @override
  Future<void> ensureReady() {
    return _webviewLoadCompleter.future;
  }

  void _handleClientReady(List<dynamic> args) async {
    if (_webviewLoadCompleter.isCompleted) return;

    _webviewLoadCompleter.complete();
  }

  Stream<bool> get isInspectableStream => _isInspectableStreamController.stream;

  final _loadingProgressNotifier = ValueNotifier<double>(0.0);
  ValueListenable<double> get loadingProgressNotifier {
    return _loadingProgressNotifier;
  }

  late HeadlessInAppWebView _innerWebView;
  final List<StreamSubscription> _subscriptions = [];

  void _buildWebViewForAttestor({required bool isInspectable}) {
    final log = logger.child('AttestorWebViewClient.innerWebView');
    log.info('Building webview for attestor');

    _loadingProgressNotifier.value = 0.0;

    final initialSettings = InAppWebViewSettings(
      userAgent: "reclaimsdk",
      isInspectable: isInspectable,
      useHybridComposition: false,
      rendererPriorityPolicy: RendererPriorityPolicy(
        waivedWhenNotVisible: false,
        rendererRequestedPriority: RendererPriority.RENDERER_PRIORITY_IMPORTANT,
      ),
    );
    _innerWebView = HeadlessInAppWebView(
      initialSettings: initialSettings,
      initialUrlRequest: URLRequest(url: WebUri.uri(attestorBrowserRpcUrl)),
      onWebViewCreated: (controller) async {
        log.info('onWebViewCreated');
        controller.addJavaScriptHandler(
          handlerName: 'HostRpcMessageHandler',
          callback: (args) {
            _handleHostRpcMessage(args);
          },
        );
        controller.addJavaScriptHandler(handlerName: 'ClientReadyHandler', callback: _handleClientReady);
        controller.addUserScript(
          userScript: UserScript(
            source: _attestorInAppWebViewUserScript(attestorBrowserRpcUrl, debugLabel),
            injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
          ),
        );
      },
      onLoadStart: (controller, url) async {
        log.info('onLoadStart');
        _loadingProgressNotifier.value = 0.1;
      },
      onLoadStop: (controller, url) async {
        log.info('onLoadStop');
        _loadingProgressNotifier.value = 1.0;
        _handleClientReady(const []);
      },
      onProgressChanged: (controller, progress) {
        log.info({'tag': 'onProgressChanged', 'progress': progress});
        _loadingProgressNotifier.value = progress / 100.0;
      },
      onRenderProcessGone: (controller, details) {
        log.severe('os murdered webview', details);
        _subscriptions.clear();
        _innerWebView.dispose();
        _webviewLoadCompleter.completeError(AttestorClientGoneException('render process gone. $details'));
        _webviewLoadCompleter = Completer<void>();
        _buildWebViewForAttestor(isInspectable: isInspectable);
      },
    );
    _subscriptions.add(
      isInspectableStream.listen((it) async {
        await ensureReady();
        final controller = _innerWebView.webViewController;
        if (controller == null) {
          log.warning('Webview controller is null');
          return;
        }
        final settings = (await controller.getSettings() ?? initialSettings).copy();
        settings.isInspectable = it;
        controller.setSettings(settings: settings);
      }),
    );

    _innerWebView.run();
  }

  @override
  Future<bool> isPlatformSupported() async {
    return ReclaimProxyOperator.instance.isPlatformSupported();
  }

  @override
  String toString() {
    return 'AttestorWebViewClient(attestorBrowserRpcUrl: $attestorBrowserRpcUrl, debugLabel: $debugLabel, createdAt: $createdAt, age: ${AttestorJsClient.getClientAge(this)})';
  }
}

String _attestorInAppWebViewUserScript(Uri attestorBrowserRpcUrl, String debugLabel) =>
    """
globalThis.ATTESTOR_BASE_URL = "${attestorBrowserRpcUrl.origin}"
globalThis.RPC_CHANNEL_NAME = "${AttestorJsClient.hostMessengerChannelName}"

const _setupMessaging = (event) => {
  try {
    globalThis.ATTESTOR_BASE_URL = "${attestorBrowserRpcUrl.origin}"
  	globalThis.RPC_CHANNEL_NAME = "${AttestorJsClient.hostMessengerChannelName}"

    const sendMessageToHost = (name, message) => {
      return window.flutter_inappwebview.callHandler(name, message);
    }

    window.HostMessenger = {
      notifyReady: () => {
        sendMessageToHost('ClientReadyHandler', true);
      },
      consoleLog: (level, logs) => {
        sendMessageToHost('HostRpcMessageHandler', JSON.stringify({
          'type': 'console',
          'data': logs,
          'source': 'webview-console',
          'level': level,
        }));
      },
      postMessage: (message) => {
        sendMessageToHost('HostRpcMessageHandler', message);
      },
    };
    window.backupMessenger = window.HostMessenger;

    const setupConsoleLogs = () => {
      const logLevels = ['log', 'debug', 'info', 'warn', 'error'];
      for (const level of logLevels) {
        const originalLog = console[level];
        console[level] = (...log) => {
          originalLog(...log);
          window.HostMessenger.consoleLog(level, log);
        }
      }
      window.onunhandledrejection = (err) => {
        console.error(`unhandled reject: \${err.reason} \${err.reason.stack} `)
      }
    }

    setupConsoleLogs();

    window.HostMessenger.notifyReady();
  } catch (e) {
    console.error('Error in DOMContentLoaded', e);
  }
};

addEventListener("DOMContentLoaded", _setupMessaging);

_setupMessaging();
""";
