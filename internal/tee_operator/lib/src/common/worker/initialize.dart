import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:logging/logging.dart';
import 'package:reclaim_tee_operator_flutter/src/common/libreclaim/libreclaim.dart';

import '../algorithm/algorithm.dart';
import '../download/download.dart';
import 'isolate_worker/isolate_worker.dart';

final _logger = Logger('reclaim_inapp_sdk.reclaim_tee_operator.worker.initialize');

class InitAlgorithmInput {
  final ProverAlgorithmType algorithm;
  final List<String> keyAssetUrls;
  final List<String> r1csAssetUrls;

  const InitAlgorithmInput({required this.algorithm, required this.keyAssetUrls, required this.r1csAssetUrls});
}

class InitAlgorithmRunnable extends Runnable<InitAlgorithmInput, bool> {
  final String httpCacheDirName;

  const InitAlgorithmRunnable({required this.httpCacheDirName});

  @override
  Future<bool> call(
    InitAlgorithmInput input, {

    required String debugLabel,
    required ReceivePort receivePort,
    required SendPort sendPort,
  }) {
    return initializeAlgorithm(input.algorithm, input.keyAssetUrls, input.r1csAssetUrls, httpCacheDirName);
  }

  static Future<Uint8List?> downloadWithMirrors({
    required List<String> mirrors,
    required String assetNameDebug,
    required String assetTypeDebug,
    required String? httpCacheDirName,
  }) async {
    final log = Logger('${_logger.fullName}.downloadWithMirrors');
    log.fine('Downloading $assetTypeDebug asset for $assetNameDebug');
    final stopwatch = Stopwatch()..start();
    for (final downloadUrl in mirrors) {
      try {
        log.fine('Downloading $assetTypeDebug asset for $assetNameDebug from $downloadUrl');
        final asset = await downloadWithHttp(downloadUrl, cacheDirName: httpCacheDirName);
        if (asset == null) continue;
        stopwatch.stop();
        log.info(
          'Downloaded $assetTypeDebug asset for $assetNameDebug from $downloadUrl, elapsed ${stopwatch.elapsed}',
        );
        return asset;
      } catch (e, s) {
        log.warning('Failed to download $assetTypeDebug asset for $assetNameDebug from $downloadUrl', e, s);
      }
    }
    stopwatch.stop();
    log.info('Failed to download $assetTypeDebug asset for $assetNameDebug, elapsed ${stopwatch.elapsed}');
    return null;
  }

  static Future<bool> initializeAlgorithm(
    ProverAlgorithmType algorithm,
    List<String> keyAssetUrls,
    List<String> r1csAssetUrls,
    String? httpCacheDirName,
  ) async {
    final provingKeyFuture = downloadWithMirrors(
      mirrors: keyAssetUrls,
      assetNameDebug: algorithm.name,
      assetTypeDebug: 'key',
      httpCacheDirName: httpCacheDirName,
    );
    final r1csFuture = downloadWithMirrors(
      mirrors: r1csAssetUrls,
      assetNameDebug: algorithm.name,
      assetTypeDebug: 'r1cs',
      httpCacheDirName: httpCacheDirName,
    );

    await Future.wait([provingKeyFuture, r1csFuture]);

    final provingKey = await provingKeyFuture;
    final r1cs = await r1csFuture;

    if (provingKey == null || r1cs == null) {
      _logger.warning({
        'reason': 'Failed to download key or r1cs for ${algorithm.name}',
        'provingKey.length': provingKey?.length,
        'r1cs.length': r1cs?.length,
      });
      return false;
    }

    Pointer<GoSlice>? provingKeyPointer;
    Pointer<GoSlice>? r1csPointer;
    try {
      provingKeyPointer = GoSliceExtension.fromUint8List(provingKey);
      r1csPointer = GoSliceExtension.fromUint8List(r1cs);

      const canInitializeInIsolate = bool.fromEnvironment(
        'org.reclaimprotocol.tee_operator.CAN_INITIALIZE_PROVER_IN_ISOLATE',
        // Disabled by default because this was causing oom problems with aggressive os applied optimizations
        defaultValue: true,
      );

      int result = 0;

      _logger.fine('Running InitAlgorithm new for ${algorithm.name}');
      final stopwatch = Stopwatch()..start();
      if (canInitializeInIsolate) {
        // Sharing pointer address between isolates because native allocated memory can be accessed by other isolates
        // Direct sharing of pointers accross isolate boundaries is not supported in some versions of Dart.
        // See: https://github.com/dart-lang/sdk/commit/eba0e68e1a9a6e81acb84de8e60ca299335ec24b
        final provingKeyAddress = provingKeyPointer.address;
        final r1csAddress = r1csPointer.address;
        result = await Isolate.run(() {
          final bindings = ReclaimBindings.instance;
          return bindings.initializeAlgorithm(
            algorithm.id,
            Pointer.fromAddress(provingKeyAddress).cast<GoSlice>().ref,
            Pointer.fromAddress(r1csAddress).cast<GoSlice>().ref,
          );
        });
      } else {
        final bindings = ReclaimBindings.instance;
        result = bindings.initializeAlgorithm(algorithm.id, provingKeyPointer.ref, r1csPointer.ref);
      }

      stopwatch.stop();
      _logger.info('Init complete for ${algorithm.name}, elapsed ${stopwatch.elapsed}');

      _logger.finest({
        'func': 'InitAlgorithm',
        'args': {
          'algorithm': {'name': algorithm.name, 'id': algorithm.id},
          'provingKey.length': provingKey.length,
          'r1cs.length': r1cs.length,
        },
        'return': result,
      });

      return result == 1;
    } finally {
      if (provingKeyPointer != null) {
        calloc.free(provingKeyPointer.ref.data);
        calloc.free(provingKeyPointer);
      }
      if (r1csPointer != null) {
        calloc.free(r1csPointer.ref.data);
        calloc.free(r1csPointer);
      }
    }
  }
}
