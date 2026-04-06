/// Native Network FFI bindings for iOS VPN compatibility
///
/// This module provides FFI bindings to enable native networking in the
/// Go shared library, allowing iOS to handle network connections via
/// URLSession/NWConnection which properly respect VPN tunnels.
library;

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:reclaim_tee_operator_flutter/src/common/libreclaim/libreclaim.dart';
import 'package:reclaim_tee_operator_flutter/src/common/logger.dart';

// =============================================================================
// Callback Function Types
// =============================================================================

/// Native connection handle - opaque pointer
/// This should be casted to `Pointer<Int>` in dart for use.
typedef NetworkConnectionIdentifier = Pointer<Void>;

/// Connect callback: (reqId, connType, url, timeoutMs) -> void
typedef NativeConnectCallbackNative = Void Function(Int64 reqId, Int connType, Pointer<Char> url, Int timeoutMs);
typedef NativeConnectCallback = void Function(int reqId, int connType, Pointer<Utf8> url, int timeoutMs);

/// Read callback: (reqId, handle, maxBytes, timeoutMs) -> void
typedef NativeReadCallbackNative =
    Void Function(Int64 reqId, NetworkConnectionIdentifier handle, Int maxBytes, Int timeoutMs);
typedef NativeReadCallback = void Function(int reqId, NetworkConnectionIdentifier handle, int maxBytes, int timeoutMs);

/// Write callback: (reqId, handle, data, length) -> void
typedef NativeWriteCallbackNative =
    Void Function(Int64 reqId, NetworkConnectionIdentifier handle, Pointer<UnsignedChar> data, Int length);
typedef NativeWriteCallback =
    void Function(int reqId, NetworkConnectionIdentifier handle, Pointer<Uint8> data, int length);

/// Close callback: (handle) -> void
typedef NativeCloseCallbackNative = Void Function(NetworkConnectionIdentifier handle);
typedef NativeCloseCallback = void Function(NetworkConnectionIdentifier handle);

/// Connection types
abstract class ConnectionType {
  static const int websocket = 1;
  static const int tcp = 2;
}

/// Error codes for native network operations
abstract class NativeNetError {
  static const int success = 0;
  static const int unknown = -1;
  static const int timeout = -2;
  static const int eof = -3;
  static const int closed = -4;
  static const int connectFailed = -5;
}

// =============================================================================
// Library Function Types
// =============================================================================

/// enable_native_networking function type
typedef EnableNativeNetworkingNative =
    Int32 Function(
      Pointer<NativeFunction<NativeConnectCallbackNative>> connectCb,
      Pointer<NativeFunction<NativeReadCallbackNative>> readCb,
      Pointer<NativeFunction<NativeWriteCallbackNative>> writeCb,
      Pointer<NativeFunction<NativeCloseCallbackNative>> closeCb,
    );
typedef EnableNativeNetworking =
    int Function(
      Pointer<NativeFunction<NativeConnectCallbackNative>> connectCb,
      Pointer<NativeFunction<NativeReadCallbackNative>> readCb,
      Pointer<NativeFunction<NativeWriteCallbackNative>> writeCb,
      Pointer<NativeFunction<NativeCloseCallbackNative>> closeCb,
    );

/// disable_native_networking function type
typedef DisableNativeNetworkingNative = Void Function();
typedef DisableNativeNetworking = void Function();

/// Provides delegated net.Conn implementation for use by reclaim protocol library for
/// managing native networking for iOS VPN compatibility
class NetworkConnectionManager {
  static NetworkConnectionManager? _instance;
  static NetworkConnectionManager get instance => _instance ??= NetworkConnectionManager._();

  final ReclaimBindings _lib;

  bool _isEnabled = false;

  /// Connection handler - must be set before enabling native networking
  NetworkConnectionHandler? connectionHandler;

  NativeCallable<NativeConnectCallbackNative>? _connectCb;
  NativeCallable<NativeReadCallbackNative>? _readCb;
  NativeCallable<NativeWriteCallbackNative>? _writeCb;
  NativeCallable<NativeCloseCallbackNative>? _closeCb;

  NetworkConnectionManager._() : _lib = ReclaimBindings.instance;

  /// Whether native networking is currently enabled
  bool get isEnabled => _isEnabled;

  /// Enable native networking with the configured connection handler
  ///
  /// Returns true if successfully enabled, false otherwise.
  /// Throws if no connection handler is configured.
  bool enable() {
    if (_isEnabled) return true;

    if (connectionHandler == null) {
      throw StateError('No connection handler configured. Set connectionHandler before calling enable().');
    }

    _connectCb = NativeCallable<NativeConnectCallbackNative>.listener(_connectCallback);
    _readCb = NativeCallable<NativeReadCallbackNative>.listener(_readCallback);
    _writeCb = NativeCallable<NativeWriteCallbackNative>.listener(_writeCallback);
    _closeCb = NativeCallable<NativeCloseCallbackNative>.listener(_closeCallback);

    final result = ReclaimBindings.instance.enableNativeNetworking(
      _connectCb!.nativeFunction,
      _readCb!.nativeFunction,
      _writeCb!.nativeFunction,
      _closeCb!.nativeFunction,
    );

    _isEnabled = result != 0;
    return _isEnabled;
  }

  /// Disable native networking
  void disable() {
    if (!_isEnabled) return;
    _lib.disableNativeNetworking();
    _isEnabled = false;

    _connectCb?.close();
    _readCb?.close();
    _writeCb?.close();
    _closeCb?.close();

    _connectCb = null;
    _readCb = null;
    _writeCb = null;
    _closeCb = null;
  }
}

// =============================================================================
// Static Callback Implementations
// =============================================================================

final _callbackLogger = sdkLogger.child('network_connection_manager');

/// Static connect callback that delegates to the connection handler
void _connectCallback(int reqId, int connType, Pointer<Char> urlPtr, int timeoutMs) async {
  try {
    final handler = NetworkConnectionManager.instance.connectionHandler;
    if (handler == null) {
      _submitConnectError(reqId, NativeNetError.unknown, 'No handler configured');
      return;
    }

    final url = urlPtr.toDartString();

    final handle = await handler.connect(connType, url, timeoutMs);
    ReclaimBindings.instance.submitConnectResult(reqId, handle, NativeNetError.success, nullptr);
  } catch (e, s) {
    _callbackLogger.warning('Connect callback failed', e, s);
    // Preserve specific error codes from NativeNetworkException
    if (e is NativeNetworkException) {
      _submitConnectError(reqId, e.errorCode, e.message ?? e.toString());
    } else {
      _submitConnectError(reqId, NativeNetError.connectFailed, e.toString());
    }
  }
}

void _submitConnectError(int reqId, int errorCode, String message) {
  final errMsgNative = message.toNativeUtf8().cast<Char>();
  ReclaimBindings.instance.submitConnectResult(reqId, nullptr, errorCode, errMsgNative);
  calloc.free(errMsgNative);
}

/// Static read callback that delegates to the connection handler
void _readCallback(int reqId, NetworkConnectionIdentifier handle, int maxBytes, int timeoutMs) async {
  try {
    final handler = NetworkConnectionManager.instance.connectionHandler;
    if (handler == null) {
      ReclaimBindings.instance.submitReadResult(reqId, nullptr, 0, NativeNetError.unknown);
      return;
    }

    final data = await handler.read(handle, maxBytes, timeoutMs);
    if (data == null) {
      ReclaimBindings.instance.submitReadResult(reqId, nullptr, 0, NativeNetError.eof);
    } else {
      final dataPtr = calloc<Uint8>(data.length);
      dataPtr.asTypedList(data.length).setAll(0, data);
      ReclaimBindings.instance.submitReadResult(
        reqId,
        dataPtr.cast<UnsignedChar>(),
        data.length,
        NativeNetError.success,
      );
      calloc.free(dataPtr);
    }
  } catch (e, s) {
    _callbackLogger.warning('Read callback failed', e, s);
    if (e is NativeNetworkException) {
      ReclaimBindings.instance.submitReadResult(reqId, nullptr, 0, e.errorCode);
    } else {
      ReclaimBindings.instance.submitReadResult(reqId, nullptr, 0, NativeNetError.unknown);
    }
  }
}

/// Static write callback that delegates to the connection handler
void _writeCallback(int reqId, NetworkConnectionIdentifier handle, Pointer<UnsignedChar> dataPtr, int length) async {
  try {
    final handler = NetworkConnectionManager.instance.connectionHandler;
    if (handler == null) {
      ReclaimBindings.instance.submitWriteResult(reqId, 0, NativeNetError.unknown);
      return;
    }

    final data = dataPtr.cast<Uint8>().asTypedList(length);
    final written = await handler.write(handle, Uint8List.fromList(data));
    ReclaimBindings.instance.submitWriteResult(reqId, written, NativeNetError.success);
  } catch (e, s) {
    _callbackLogger.warning('Write callback failed', e, s);
    if (e is NativeNetworkException) {
      ReclaimBindings.instance.submitWriteResult(reqId, 0, e.errorCode);
    } else {
      ReclaimBindings.instance.submitWriteResult(reqId, 0, NativeNetError.unknown);
    }
  }
}

/// Static close callback that delegates to the connection handler
void _closeCallback(NetworkConnectionIdentifier handle) async {
  try {
    final handler = NetworkConnectionManager.instance.connectionHandler;
    await handler?.close(handle);
  } catch (e, s) {
    _callbackLogger.warning('Close callback failed', e, s);
  }
}

// =============================================================================
// Helper Functions
// =============================================================================

/// Exception for native network errors
class NativeNetworkException implements Exception {
  final int errorCode;
  final String? message;

  NativeNetworkException(this.errorCode, [this.message]);

  @override
  String toString() => 'NativeNetworkException($errorCode): $message';
}

/// Interface for handling native network connections
///
/// Implement this interface to provide platform-specific networking
/// that respects VPN tunnels (e.g., using iOS NWConnection or URLSession).
abstract class NetworkConnectionHandler {
  /// Connect to the given URL
  ///
  /// [connType] is either [ConnectionType.websocket] or [ConnectionType.tcp]
  /// [url] is the target URL or address (e.g., "wss://example.com/ws" or "example.com:443")
  /// [timeoutMs] is the connection timeout in milliseconds
  ///
  /// Returns an opaque handle to the connection.
  /// Throws [NativeNetworkException] on failure.
  Future<NetworkConnectionIdentifier> connect(int connType, String url, int timeoutMs);

  /// Read data from the connection
  ///
  /// [handle] is the connection handle from [connect]
  /// [maxBytes] is the maximum number of bytes to read
  /// [timeoutMs] is the read timeout in milliseconds
  ///
  /// Returns the data read, or null for EOF.
  /// Throws [NativeNetworkException] on failure.
  Future<Uint8List?> read(NetworkConnectionIdentifier handle, int maxBytes, int timeoutMs);

  /// Write data to the connection
  ///
  /// [handle] is the connection handle from [connect]
  /// [data] is the data to write
  ///
  /// Returns the number of bytes written.
  /// Throws [NativeNetworkException] on failure.
  Future<int> write(NetworkConnectionIdentifier handle, Uint8List data);

  /// Close the connection
  ///
  /// [handle] is the connection handle from [connect]
  Future<void> close(NetworkConnectionIdentifier handle);
}
