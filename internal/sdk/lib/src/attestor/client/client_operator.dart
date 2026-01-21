import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket/web_socket.dart';

import '../../../logging.dart';
import '../../utils/json.dart';
import '../../utils/random.dart';
import '../../widgets/claim_creation/claim_creation.dart';
import '../operator/proxy_operator.dart';
import 'base.dart';

abstract mixin class AttestorClientOperator implements AttestorJsClient {
  Future<void> handleIncomingMessage(String rpcMessageString) async {
    final log = logger.child('handleIncomingMessage');
    log.finest({'tag': 'rpc.message', 'value': rpcMessageString});

    String? maybeId;

    try {
      final Map<String, Object?> message = json.decode(rpcMessageString);

      final id = message['id']?.toString() ?? '';
      final type = message['type']?.toString() ?? '';

      maybeId = id;

      final didHandle = await _handleRequest(id, type, message);
      if (!didHandle) {
        log.warning('Unhandled request by id $id and type $type');
      }
    } catch (e, s) {
      try {
        final id = maybeId ?? '<unknown>';

        log.severe('Error handling rpc message by id $id', e, s);

        final manager = getProcessManagerById(id);

        final response = RpcResponseError(id: id, data: RpcResponseErrorData.fromException(e, s));

        // notify this error as an update using the controller
        manager?.emitUpdate.add(response.toJson());

        await postMessage(response);
      } catch (e, s) {
        log.severe('Error handling error for rpc message by id $maybeId', e, s);
      }
    }
  }

  Future<bool> _handleRequest(String id, String type, Map<String, Object?> message) async {
    final log = logger.child('_handleRequest');

    log.fine('handling request of type "$type" and id "$id"');

    switch (type.toString().toLowerCase().trim()) {
      case 'console':
        _handleRpcLog(message);
        return true;
      case 'zkprove':
      case 'executezkfunctionv3':
      case 'executeoprffunctionv3':
        return _onComputeZKProve(id, type, message);
      case 'updateproviderparams':
        return _onUpdateProviderParams(id, message);
      case 'error':
        return _handleError(id, type, message);
      case 'connectws':
        return _onConnectWs(id, type, message);
      case 'disconnectws':
        return _onDisconnectWs(id, type, message);
      case 'sendwsmessage':
        return _onSendWsMessage(id, type, message);
    }

    final manager = getProcessManagerById(id);

    if (manager == null) {
      log.warning(
        'No manager available for request $type with id $id, available managers: ${getProcessManagers().map((e) => e.process.id).toList()}',
      );
      return false;
    }
    log.fine('Using manager (id ${manager.process.id}) to respond for request of type $type and id $id');

    if (type.endsWith('Done')) {
      try {
        final data = message['response'];
        manager.completer.complete(data);
        return true;
      } catch (e, s) {
        log.warning(
          'Offending completer ${manager.completer} of manager $manager for request $type with data ${kDebugMode ? message : '<redacted>'}',
          e,
          s,
        );
        rethrow;
      }
    } else {
      log.finest({
        'Notifying update': message,
        'has listeners': manager.updatesController.hasListener,
        'process manager id': manager.process.id,
      });
      // Note: could also be an unknown request type which hasn't been handled
      manager.emitUpdate.add(message);
      return true;
    }
  }

  void _handleRpcLog(Map<String, Object?> message) {
    final log = logger.child('_handleRpcLog');
    log.info({'tag': 'attestor_client.console', 'value': message});
  }

  Future<bool> _handleError(String id, String type, Map<String, Object?> message) async {
    final log = logger.child('_handleError');

    final manager = getProcessManagerById(id);
    if (manager == null) {
      log.warning('No controller for request type $type');
      return false;
    }

    final dynamic data = message["data"];
    log.finest({'tag': 'error', 'data': data});

    final Object? error = data["message"];
    final Object? stack = data["stack"];

    manager.completer.completeError(
      AttestorRequestException(error),
      AttestorRequestException.tryParseStackTrace(stack) ?? StackTrace.current,
    );

    return true;
  }

  Future<bool> _onComputeZKProve(String id, String type, Map<String, Object?> message) async {
    final dynamic requestArgs = message['request'];
    final String fnName = requestArgs['fn'];
    final args = requestArgs['args'];

    final opr = AttestorReclaimProxyOperator.instance;

    if (!await opr.isSupported(fnName, args)) {
      // ignore unsupported requests
      return false;
    }

    if (args is! List) {
      throw ArgumentError.value(args, 'args', 'args should be a list');
    }

    final result = await opr.compute(fnName, args, addPerformanceReport);

    await postMessage(RpcResponse(id: id, type: '${type}Done', response: json.decode(result)));

    return true;
  }

  Future<bool> _onUpdateProviderParams(String id, Map<String, dynamic> decodedArgs) async {
    final log = logger.child('_onUpdateProviderParams');
    log.info('attestor request provider params update');

    final String response = decodedArgs["request"]["response"]["body"];
    final claimCreationController = ClaimCreationController.lastInstance;
    if (claimCreationController == null) {
      throw StateError('No ClaimCreationController instance is available');
    }

    final result = await claimCreationController.getUpdatedProviderParams(
      attestorClaimCreationRequestId: id.toString(),
      response: response,
    );

    Map<String, String> privateWitnessParams = {};
    Map<String, String> publicWitnessParams = {};

    // IMPORTANT: secret params should be always empty
    //added this to make sure secret params are not revealed to the witness
    result.extractedData.witnessParams.forEach((key, value) {
      if (key.contains('SECRET')) {
        privateWitnessParams[key] = value;
      } else {
        publicWitnessParams[key] = value;
      }
    });

    log.info('witness request provider params update done');

    await postMessage(
      RpcResponse(
        id: id,
        type: 'updateProviderParamsDone',
        response: {
          "params": {
            "responseMatches": result.extractedData.responseMatches.map((e) => e.toJson()).toList(),
            "responseRedactions": result.extractedData.responseRedactions.map((e) => e.toJson()).toList(),
            "paramValues": publicWitnessParams,
          },
          "secretParams": {"paramValues": privateWitnessParams},
        },
      ),
    );

    return true;
  }

  Future<bool> _onConnectWs(String requestId, String type, Map<String, Object?> message) async {
    final log = logger.child('_onConnectWs');

    final request = message['request'] as Map?;
    if (request == null) {
      throw Exception('Invalid request: $request');
    }
    final id = request['id'] as String?;
    final url = request['url'] as String?;
    if (id == null || url == null) {
      throw Exception('Invalid request: $message');
    }
    log.info('connecting ws to $url');
    final ws = await WebSocket.connect(Uri.parse(url));
    addSocket(id, ws);
    ws.events.listen((ev) {
      switch (ev) {
        case TextDataReceived():
          final data = ev.text;
          log.info('TEXT RECEIVED: $ev');
          postMessage(
            RpcRequest(
              id: generateRequestId(),
              channel: AttestorJsClient.hostMessengerChannelName,
              type: 'sendWsMessage',
              request: {'id': id, 'data': data},
            ),
          );
          break;
        case BinaryDataReceived():
          final data = ev.data;
          log.info('BINARY RECEIVED: $ev');
          postMessage(
            RpcRequest(
              id: generateRequestId(),
              channel: AttestorJsClient.hostMessengerChannelName,
              type: 'sendWsMessage',
              request: {'id': id, 'data': bytesToBase64Json(data)},
            ),
          );
          break;
        case CloseReceived():
          log.info('CLOSE RECEIVED: $ev');
          postMessage(
            RpcRequest(
              id: generateRequestId(),
              channel: AttestorJsClient.hostMessengerChannelName,
              type: 'disconnectWs',
              request: {'id': id},
            ),
          );
          removeSocket(id);
          break;
      }
    });
    await postMessage(RpcResponse(id: requestId, type: '${type}Done', response: {}));
    return true;
  }

  Future<bool> _onDisconnectWs(String requestId, String type, Map<String, Object?> message) async {
    final log = logger.child('_onDisconnectWs');

    final request = message['request'] as Map;
    final id = request['id'] as String;
    final ws = getSocketById(id);
    if (ws != null) {
      removeSocket(id);
    } else {
      log.warning('WebSocket not found for id $id');
    }
    await postMessage(RpcResponse(id: requestId, type: '${type}Done', response: {}));
    return true;
  }

  Future<bool> _onSendWsMessage(String requestId, String type, Map<String, Object?> message) async {
    final log = logger.child('_onSendWsMessage');

    final request = message['request'] as Map;
    final id = request['id'] as String;
    final data = request['data'];
    final ws = getSocketById(id);
    log.finest('sendWsMessage SENDING TO WS: $id => (${data.runtimeType})');
    if (ws == null) {
      throw Exception('WebSocket not found');
    }
    if (data is String) {
      ws.sendText(data);
    } else if (data is Map && data['type'] == 'uint8array') {
      final bytes = base64.decode(data['value'] as String);
      ws.sendBytes(bytes);
    } else {
      throw Exception('Invalid data type: ${data.runtimeType}');
    }
    await postMessage(RpcResponse(id: requestId, type: '${type}Done', response: {}));
    return true;
  }
}
