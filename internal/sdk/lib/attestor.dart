import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:reclaim_flutter_sdk/src/attestor/attestor.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/attestor/operator/callback.dart';
import 'utils/flags.dart';
import 'utils/reusable_resource_pool.dart';

export 'src/attestor/operator/callback.dart';
export 'package:reclaim_flutter_sdk/src/attestor/attestor.dart'
    show
        AttestorClient,
        AttestorClaimOptions,
        AttestorProcess,
        AttestorClaimResponse;

class Attestor {
  Attestor();

  static final instance = Attestor();

  Future<AttestorClient> _createAttestorWebView() async {
    final prefs = await SharedPreferences.getInstance();
    final effectiveUrl =
        _attestorUrl ?? Uri.parse(Flags.getAttestorBrowserRpcUrl(prefs));
    _attestorUrl = effectiveUrl;

    final attestor = AttestorWebViewClient(attestorBrowserRpcUrl: effectiveUrl);

    if (_level != null) {
      attestor.setAttestorDebugLevel(_level!);
    }

    final callback = _computeAttestorProof;
    if (callback != null) {
      attestor.zkOperator = CallbackAttestorZkOperator.withComputeProof(
        callback,
      );
    }

    return attestor;
  }

  Future<void> _disposeAttestor(AttestorClient attestor) async {
    return attestor.dispose();
  }

  @protected
  late final _attestorPool = ReusableResourcePool(
    initialPoolSize: 6,
    createResource: _createAttestorWebView,
    disposeResource: _disposeAttestor,
  );

  ReusableResourcePool<AttestorClient> get pool => _attestorPool;

  Future<T> useAttestor<T>(Future<T> Function(AttestorClient) use) {
    return _attestorPool.compute(use);
  }

  Future<AttestorProcess<AttestorClaimRequest, List<AttestorClaimResponse>>>
  createClaim(
    Map<String, dynamic> claimRequest, {
    required AttestorClaimOptions options,
    void Function(double progress)? onInitializationProgress,
    AttestorCreateClaimPerformanceReportCallback? onPerformanceReports,
  }) {
    return useAttestor((attestor) async {
      VoidCallback? createInitProgressListener() {
        final it = attestor;
        if (it is! AttestorWebViewClient) {
          return null;
        }
        final listenerCallback = onInitializationProgress;
        if (listenerCallback == null) return null;

        final notifier = it.loadingProgressNotifier;

        void progressListener() {
          listenerCallback(notifier.value);
        }

        notifier.addListener(progressListener);

        return () {
          notifier.removeListener(progressListener);
        };
      }

      final listenerRemover = createInitProgressListener();

      try {
        final process = attestor.createClaim(
          request: claimRequest,
          options: options,
          onPerformanceReports: onPerformanceReports,
        );

        void removeListenerAfterResponse() async {
          if (listenerRemover == null) return;
          try {
            await process.response;
          } finally {
            listenerRemover();
          }
        }

        removeListenerAfterResponse();
        return process;
      } finally {
        listenerRemover?.call();
      }
    });
  }

  String? _level;

  Future<void> setAttestorDebugLevel(String level) {
    _level = level;
    return Future.wait(
      pool.resources.map((e) => e.setAttestorDebugLevel(level).response),
    );
  }

  Uri? _attestorUrl;

  Future<void> setAttestorUrl(Uri value) async {
    if (_attestorUrl == value) {
      return;
    }
    _attestorUrl = value;
    pool.disposeResources();
    pool.peekResource;
  }

  ComputeProofForAttestorCallback? _computeAttestorProof;

  Future<void> setComputeAttestorProof(
    ComputeProofForAttestorCallback callback,
  ) async {
    if (_computeAttestorProof == callback) return;
    _computeAttestorProof = callback;
    return useAttestor((attestor) async {
      attestor.zkOperator = CallbackAttestorZkOperator.withComputeProof(
        callback,
      );
    });
  }

  Future<void> ensureReady() {
    pool.peekResource;

    return Future.wait(
      pool.resources.map((e) async {
        return e.ensureReady();
      }),
    );
  }

  Future<String> extractJSONValueIndex(String json, String jsonPath) {
    return useAttestor((attestor) {
      return attestor.extractJSONValueIndex(json, jsonPath).response;
    });
  }

  Future<String> extractHtmlElement(String html, String xpathExpression) {
    return useAttestor((attestor) {
      return attestor.extractHtmlElement(html, xpathExpression).response;
    });
  }

  Future<void> close() {
    return Future.wait([_attestorPool.close()]);
  }
}
