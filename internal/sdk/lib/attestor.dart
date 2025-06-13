import 'dart:async';

import 'package:flutter/foundation.dart';

import 'src/attestor/attestor.dart';
import 'src/constants.dart';
import 'src/data/create_claim.dart';
import 'src/utils/reusable_resource_pool.dart';

export 'src/attestor/attestor.dart';
export 'src/attestor/operator/callback.dart';

class Attestor {
  Attestor();

  static final instance = Attestor();

  FutureOr<AttestorClient> _createAttestorWebView() async {
    final effectiveUrl = _attestorUrl ?? Uri.parse(ReclaimUrls.DEFAULT_ATTESTOR_WEB_URL);
    _attestorUrl = effectiveUrl;

    final attestor = AttestorWebViewClient(attestorBrowserRpcUrl: effectiveUrl);

    if (_level != null) {
      attestor.setAttestorDebugLevel(_level!);
    }

    attestor.zkOperator = _attestorZkOperator;

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

  Future<AttestorProcess<AttestorClaimRequest, List<CreateClaimOutput>>> createClaim(
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
    return Future.wait(pool.resources.map((e) => e.setAttestorDebugLevel(level).response));
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

  AttestorZkOperator? _attestorZkOperator;

  Future<void> setZkOperator(AttestorZkOperator? operator) async {
    if (_attestorZkOperator == operator) return;
    _attestorZkOperator = operator;
    return useAttestor((attestor) async {
      attestor.zkOperator = operator;
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
