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

import '../../../../logging/logging.dart';
import '../../../../widgets/claim_creation/claim_creation.dart';
import '../../data/data.dart';
import '../../data/process.dart';
import '../../exception/exception.dart'
    show
        AttestorRequestException,
        AttestorRequestMessagingException;
import '../../operator/operator.dart';
import '../base.dart';
import 'manager.dart';
import 'message.dart';

const _rpcModule =
    'witness-sdk';

/// An attestor client that uses webview with attestor browser rpc
class AttestorWebViewClient
    extends AttestorClient {
  final Uri
      attestorBrowserRpcUrl;
  final StreamController<bool>
      _isInspectableStreamController;

  AttestorWebViewClient({
    required this.attestorBrowserRpcUrl,
    bool isInspectable =
        kDebugMode,
  }) : _isInspectableStreamController = StreamController.broadcast()..add(isInspectable) {
    _buildWebViewForAttestor(
        isInspectable: isInspectable);
  }

  final Map<String,
          AttestorRpcProcessManager>
      _processManagers =
      {};

  @override
  AttestorProcess<REQUEST, RESPONSE> sendRequest<
      REQUEST,
      RESPONSE>({
    required String
        type,
    // request should be json serializable
    required REQUEST
        request,
    required FutureOr<RESPONSE> Function(dynamic value)
        transformResponse,
  }) {
    final manager = AttestorRpcProcessManager<
        REQUEST,
        RESPONSE>.create(
      requestType:
          type,
      request:
          request,
      transformer:
          transformResponse,
    );

    final process =
        manager.process;

    _processManagers[process.id] =
        manager;

    _postMessage(
      process.createRequest(
          module: _rpcModule,
          channel: 'HostMessenger'),
    ).catchError((e,
        s) {
      final completer =
          manager.completer;
      if (completer.isCompleted)
        return;
      completer.completeError(AttestorRequestMessagingException(e),
          s);
    });

    return process;
  }

  /// Post a message to the attestor client's browser rpc handler
  Future<void>
      _postMessage(RpcMessage rpcMessage) async {
    final log =
        logging.child('AttestorWebViewClient.postMessage');

    try {
      final message =
          json.encode(rpcMessage);

      // using json.encode here to string escape the json message correctly
      final js =
          'window.postMessage(${json.encode(message)});';

      log.finest({
        'tag': 'rpc.js',
        'value': js
      });

      await ensureReady();

      _innerWebView.webViewController?.evaluateJavascript(source: js);
    } catch (e, s) {
      log.severe(
          'Error sending request',
          e,
          s);
    }
  }

  Future<bool>
      _onComputeZKProve(
    String
        id,
    AttestorZkOperator
        opr,
    String
        type,
    Map<String, Object?>
        message,
  ) async {
    final dynamic
        requestArgs =
        message['request'];
    final String
        fnName =
        requestArgs['fn'];
    final args =
        requestArgs['args'];

    if (!await opr.isSupported(
        fnName,
        args)) {
      // ignore unsupported requests
      return false;
    }

    if (args
        is! List) {
      throw ArgumentError.value(
          args,
          'args',
          'args should be a list');
    }

    final result = await opr.compute(
        fnName,
        args,
        addPerformanceReport);

    await _postMessage(
      RpcResponse(
        id: id,
        type: '${type}Done',
        module: _rpcModule,
        response: json.decode(result),
      ),
    );

    return true;
  }

  Future<bool>
      _onUpdateProviderParams(
    String
        id,
    Map<String, dynamic>
        decodedArgs,
  ) async {
    final log =
        logging.child('AttestorWebViewClient._onUpdateProviderParams');
    log.info(
        'attestor request provider params update');

    final String
        response =
        decodedArgs["request"]["response"]["body"];
    final claimCreationController =
        ClaimCreationController.lastInstance;
    if (claimCreationController ==
        null) {
      throw StateError('No ClaimCreationController instance is available');
    }

    final result =
        await claimCreationController.getUpdatedProviderParams(
      attestorClaimCreationRequestId:
          id.toString(),
      response:
          response,
    );

    Map<String, String>
        privateWitnessParams =
        {};
    Map<String, String>
        publicWitnessParams =
        {};

    // IMPORTANT: secret params should be always empty
    //added this to make sure secret params are not revealed to the witness
    result
        .extractedData
        .witnessParams
        .forEach((key, value) {
      if (key.contains('SECRET')) {
        privateWitnessParams[key] = value;
      } else {
        publicWitnessParams[key] = value;
      }
    });

    log.info(
        'witness request provider params update done');

    await _postMessage(
      RpcResponse(
        id: id,
        type: 'updateProviderParamsDone',
        module: _rpcModule,
        response: {
          "params": {
            "responseMatches": result.extractedData.responseMatches.map((e) => e.toJson()).toList(),
            "responseRedactions": result.extractedData.responseRedactions.map((e) => e.toJson()).toList(),
            "paramValues": publicWitnessParams,
          },
          "secretParams": {
            "paramValues": privateWitnessParams
          },
        },
      ),
    );

    return true;
  }

  Future<bool>
      _handleRequest(
    String
        id,
    String
        type,
    Map<String, Object?>
        message,
  ) async {
    final log =
        logging.child('AttestorWebViewClient.handleRequest');

    switch (type
        .toString()
        .toLowerCase()
        .trim()) {
      case 'console':
        _handleRpcLog([
          message
        ]);
        return true;
      case 'zkprove':
      case 'executezkfunctionv3':
      case 'executeoprffunctionv3':
        final opr = zkOperator;
        if (opr == null) {
          log.warning('No operator for handling request type $type');
          throw StateError(
            'No ZK operator available to handle request type $type',
          );
        }
        return _onComputeZKProve(id, opr, type, message);
      case 'updateproviderparams':
        return _onUpdateProviderParams(id, message);
      case 'error':
        final controller = _processManagers[id];
        if (controller == null) {
          log.warning('No controller for request type $type');
          return false;
        }

        final dynamic data = message["data"];
        log.finest({
          'tag': 'error',
          'data': data
        });

        final Object? error = data["message"];
        final Object? stack = data["stack"];

        controller.completer.completeError(
          AttestorRequestException(error),
          AttestorRequestException.tryParseStackTrace(stack) ?? StackTrace.current,
        );

        return true;
    }

    final controller =
        _processManagers[id];
    if (controller ==
        null) {
      return false;
    }

    if (type
        .endsWith('Done')) {
      try {
        final data = message['response'];
        controller.completer.complete(data);
        return true;
      } catch (e, s) {
        log.warning(
          'Offending completer ${controller.completer} of controller $controller for request $type with data ${kDebugMode ? message : '<redacted>'}',
          e,
          s,
        );
        rethrow;
      }
    } else {
      // Note: could also be an unknown request type which hasn't been handled
      controller.emitUpdate.add(message);
      return true;
    }
  }

  void _handleHostRpcMessage(
      List<dynamic>
          args) async {
    final log =
        logging.child('AttestorWebViewClient.handleHostRpcMessage');
    log.finest({
      'tag':
          'rpc.message',
      if (args.isNotEmpty)
        'value': args[0]
    });

    try {
      final Map<String, Object?>
          message =
          json.decode(args[0]);

      final id =
          message['id'].toString();
      final type =
          message['type'].toString();

      try {
        final didHandle = await _handleRequest(id, type, message);
        if (!didHandle) {
          log.warning('Unhandled request by id $id');
        }
      } catch (e, s) {
        final controller = _processManagers[id];
        // notify this error as an update using the controller
        controller?.emitUpdate.add({
          'type': 'error',
          'error': e,
          'stackTrace': s,
        });
        // we rethrow the error so that the wrapping try-catch block can log the error
        rethrow;
      }
    } catch (e, s) {
      log.severe(
          'Error handling rpc message',
          e,
          s);
    }
  }

  @override
  Future<void>
      dispose() async {
    final log =
        logging.child('AttestorWebViewClient.dispose');

    try {
      await _innerWebView.dispose();
    } catch (e, s) {
      log.warning(
          'Error disposing webview',
          e,
          s);
    }

    _isInspectableStreamController
        .close();
    _loadingProgressNotifier
        .dispose();
    if (!_webviewLoadCompleter
        .isCompleted) {
      _webviewLoadCompleter.completeError(
        Exception('_innerWebView disposed before initialization completed'),
      );
    }

    for (final controller
        in _processManagers.values) {
      controller.onCancel();
    }

    _processManagers
        .clear();
  }

  final _webviewLoadCompleter =
      Completer<void>();

  @override
  Future<void>
      ensureReady() {
    return _webviewLoadCompleter
        .future;
  }

  void _handleClientReady(
      List<dynamic>
          args) {
    if (_webviewLoadCompleter
        .isCompleted)
      return;

    _webviewLoadCompleter
        .complete();
  }

  Stream<bool>
      get isInspectableStream =>
          _isInspectableStreamController.stream;

  final _loadingProgressNotifier =
      ValueNotifier<double>(0.0);
  ValueListenable<double>
      get loadingProgressNotifier {
    return _loadingProgressNotifier;
  }

  void _handleRpcLog(
      List<dynamic>
          args) {
    final log =
        logging.child('AttestorWebViewClient.log');
    log.info({
      'tag':
          'rpc.console',
      if (args.isNotEmpty)
        'value': args[0]
    });
  }

  late HeadlessInAppWebView
      _innerWebView;

  void _buildWebViewForAttestor(
      {required bool
          isInspectable}) {
    final log =
        logging.child('AttestorWebViewClient.innerWebView');

    final initialSettings =
        InAppWebViewSettings(
      userAgent:
          "reclaimsdk",
      isInspectable:
          isInspectable,
      useHybridComposition:
          false,
      rendererPriorityPolicy:
          RendererPriorityPolicy(
        waivedWhenNotVisible: false,
        rendererRequestedPriority: RendererPriority.RENDERER_PRIORITY_IMPORTANT,
      ),
    );
    _innerWebView =
        HeadlessInAppWebView(
      initialSettings:
          initialSettings,
      initialUrlRequest:
          URLRequest(url: WebUri.uri(attestorBrowserRpcUrl)),
      onWebViewCreated:
          (controller) async {
        controller.addJavaScriptHandler(
          handlerName: 'AttestorRpcLogHandler',
          callback: _handleRpcLog,
        );
        controller.addJavaScriptHandler(
          handlerName: 'HostRpcMessageHandler',
          callback: _handleHostRpcMessage,
        );
        controller.addJavaScriptHandler(
          handlerName: 'ClientReadyHandler',
          callback: _handleClientReady,
        );
        controller.addUserScript(
          userScript: UserScript(
            source: _attestorInAppWebViewUserScript,
            injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
          ),
        );
      },
      onLoadStart:
          (controller, url) async {
        _loadingProgressNotifier.value = 0.1;
      },
      onLoadStop:
          (controller, url) async {
        _loadingProgressNotifier.value = 1.0;
      },
      onProgressChanged:
          (controller, progress) {
        _loadingProgressNotifier.value = progress / 100.0;
      },
    );
    isInspectableStream
        .listen((it) async {
      await ensureReady();
      final controller =
          _innerWebView.webViewController;
      if (controller ==
          null) {
        log.warning('Webview controller is null');
        return;
      }
      final settings =
          (await controller.getSettings() ?? initialSettings).copy();
      settings.isInspectable =
          it;
      controller.setSettings(settings: settings);
    });

    _innerWebView
        .run();
  }
}

const _attestorInAppWebViewUserScript =
    """
const sendMessageToHost = (name, message) => {
  return window.flutter_inappwebview.callHandler(name, message);
}

window.HostMessenger = {
  notifyReady: () => {
    sendMessageToHost('ClientReadyHandler', true);
  },
  consoleLog: (level, logs) => {
    sendMessageToHost('AttestorRpcLogHandler', {
      'type': 'console',
      'data': logs,
      'source': 'attestor-rpc',
      'level': level,
    });
  },
  postMessage: (message) => {
    sendMessageToHost('HostRpcMessageHandler', message);
  },
};

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
""";
