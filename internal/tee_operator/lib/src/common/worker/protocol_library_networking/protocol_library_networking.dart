import 'package:reclaim_tee_operator_flutter/src/common/logger.dart';

import '../isolate_worker/isolate_worker.dart';

import 'network_connection/ios_native_network.dart';
import 'network_connection/native_network_impl.dart';

typedef ModuleNetworkingRequest = ({int algorithmId, int syncSignalMemoryAddress});

class ReclaimLibraryDelegatedNetworkConnectionRunnable extends Runnable<void, bool> {
  ReclaimLibraryDelegatedNetworkConnectionRunnable();

  static bool _isInitialized = false;
  static NativeNetworkConnectionHandler? _connectionHandler;
  static final _logger = sdkLogger.child('ReclaimLibraryDelegatedNetworkConnectionRunnable');

  @override
  Future<bool> call(
    void input, {
    required String debugLabel,
    required ReceivePort receivePort,
    required SendPort sendPort,
  }) async {
    if (_isInitialized) return true;
    try {
      _connectionHandler = await NativeNetworkConnectionHandler.create();
      NetworkConnectionManager.instance.connectionHandler = _connectionHandler;
      _isInitialized = NetworkConnectionManager.instance.enable();
    } catch (e, s) {
      _logger.child('call').severe('Failed to initialize runnable and enable network connection manager', e, s);
    }
    return _isInitialized;
  }

  @override
  void close() {
    _isInitialized = false;
    try {
      NetworkConnectionManager.instance.disable();
      _connectionHandler?.dispose();
    } catch (e, s) {
      _logger.child('close').severe('Failed to close and dispose runnable', e, s);
    }
  }
}
