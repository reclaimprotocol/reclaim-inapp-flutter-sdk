/// Native network connection implementation using method channels for protocol library
///
/// This implementation bridges to the Swift NativeNetworkHandler class
/// which uses NWConnection for VPN-compatible networking.
library;

import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:reclaim_tee_operator_flutter/src/common/logger.dart';

import 'native_network_impl.dart';

/// iOS implementation of [NetworkConnectionHandler] using synchronous method channels
///
/// This bridges to the Swift NativeNetworkHandler which uses Network.framework
/// (NWConnection) for iOS networking that properly respects VPN tunnels.
///
/// **Note:** This synchronous implementation is not usable because iOS networking
/// is inherently asynchronous. Use [IOSNativeConnectionHandlerAsync] instead,
/// which pre-establishes connections before the protocol runs.
class NativeNetworkConnectionHandler implements NetworkConnectionHandler {
  final AsyncNativeNetworkPlugin plugin;

  NativeNetworkConnectionHandler._(this.plugin);

  static Future<NativeNetworkConnectionHandler> create() async {
    final plugin = await AsyncNativeNetworkPlugin.create();
    return NativeNetworkConnectionHandler._(plugin);
  }

  final Map<int, String> _connectedHandles = {};

  @override
  /// Establish connections
  ///
  /// Call this before enabling native networking to establish all required
  /// connections through iOS's VPN-compatible networking stack.
  ///
  /// If any connection fails, all previously established connections in this
  /// call will be cleaned up before the error is thrown.
  Future<NetworkConnectionIdentifier> connect(int connType, String url, int timeoutMs) async {
    final result = await plugin.connect(connType, url, timeoutMs);

    final errorCode = result?['errorCode'] as int? ?? NativeNetError.unknown;
    if (errorCode != NativeNetError.success) {
      final message = result?['errorMessage'] as String? ?? 'Unknown error';
      throw NativeNetworkException(errorCode, message);
    }

    final connectionId = result?['handle'] as int?;
    sdkLogger.child('NativeNetworkConnectionHandler').info('Connection established: $connectionId');
    if (connectionId == null || connectionId <= 0) {
      throw NativeNetworkException(
        NativeNetError.unknown,
        'Missing or invalid connection handle returned from native layer',
      );
    }

    _connectedHandles[connectionId] = url;

    final handlePointer = calloc<Int>();
    handlePointer.value = connectionId;
    return handlePointer.cast<Void>();
  }

  @override
  /// Read from a pre-connected handle
  Future<Uint8List?> read(Pointer<Void> connectionIdPtr, int maxBytes, int timeoutMs) async {
    final handle = connectionIdPtr.cast<Int>().value;
    sdkLogger.child('NativeNetworkConnectionHandler').config('Reading from connection: $handle');
    final connectionName = _connectedHandles[handle];
    if (connectionName == null) {
      throw NativeNetworkException(NativeNetError.closed, 'Connection "$connectionName" not found');
    }
    final result = await plugin.read(handle, maxBytes, timeoutMs);

    final errorCode = result?['errorCode'] as int? ?? NativeNetError.unknown;
    if (errorCode == NativeNetError.eof) {
      return null;
    }
    if (errorCode != NativeNetError.success) {
      sdkLogger
          .child('NativeNetworkConnectionHandler')
          .finest('Read failed: $errorCode. result=${json.encode(result)}');
      throw NativeNetworkException(errorCode);
    }

    return result?['data'] as Uint8List?;
  }

  @override
  /// Write to a pre-connected handle
  Future<int> write(Pointer<Void> connectionIdPtr, Uint8List data) async {
    final handle = connectionIdPtr.cast<Int>().value;
    sdkLogger.child('NativeNetworkConnectionHandler').config('Writing to connection: $handle');
    final connectionName = _connectedHandles[handle];
    if (connectionName == null) {
      throw NativeNetworkException(NativeNetError.closed, 'Connection "$connectionName" not found');
    }

    final result = await plugin.write(handle, data);

    if (result == null || result < 0) {
      throw NativeNetworkException(result ?? NativeNetError.unknown);
    }

    return result;
  }

  @override
  /// Close a specific connection
  Future<void> close(Pointer<Void> connectionIdPtr) async {
    final handle = connectionIdPtr.cast<Int>().value;
    sdkLogger.child('NativeNetworkConnectionHandler').config('Closing connection: $handle');

    final connectionName = _connectedHandles.remove(handle);
    if (connectionName != null) {
      await plugin.closeConnection(handle);
    }
  }

  Future<bool> dispose() async {
    return plugin.close();
  }
}

class AsyncNativeNetworkPlugin {
  final MethodChannel _channel;

  AsyncNativeNetworkPlugin._(this._channel);

  static Future<AsyncNativeNetworkPlugin> create() async {
    final channel = MethodChannel('org.reclaimprotocol.reclaim_tee_operator_flutter.native_network');
    return AsyncNativeNetworkPlugin._(channel);
  }

  Future<void> closeConnection(int handleValue) async {
    try {
      await _channel.invokeMethod('close', {'handle': handleValue});
    } catch (_) {
      // Ignore errors during cleanup
    }
  }

  Future<Map?> connect(int connType, String url, int timeoutMs) {
    final result = _channel.invokeMethod<Map>('connect', {'connType': connType, 'url': url, 'timeoutMs': timeoutMs});
    return result;
  }

  Future<Map?> read(int handleValue, int maxBytes, int timeoutMs) {
    final result = _channel.invokeMethod<Map>('read', {
      'handle': handleValue,
      'maxBytes': maxBytes,
      'timeoutMs': timeoutMs,
    });
    return result;
  }

  Future<int?> write(int handleValue, Uint8List data) {
    final result = _channel.invokeMethod<int>('write', {'handle': handleValue, 'data': data});
    return result;
  }

  Future<bool> close() async {
    // no need to close
    return true;
  }
}
