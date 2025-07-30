import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:retry/retry.dart';

import 'src/attestor/attestor.dart';
import 'src/build_env.dart';
import 'src/constants.dart';
import 'src/data/create_claim.dart';
import 'src/logging/logging.dart';
import 'src/utils/reusable_resource_pool.dart';

export 'src/attestor/attestor.dart';
export 'src/attestor/operator/callback.dart';

class Attestor {
  Attestor();

  static final instance = Attestor();

  static final _log = logging.child('Attestor');

  AttestorClient _createAttestorWebView(String debugLabel) {
    _log.info('creating attestor webview client: $debugLabel');

    final effectiveUrl = _attestorUrl ?? Uri.parse(ReclaimUrls.DEFAULT_ATTESTOR_WEB_URL);
    _attestorUrl = effectiveUrl;

    final attestor = AttestorWebViewClient(attestorBrowserRpcUrl: effectiveUrl, debugLabel: debugLabel);

    if (_level != null) {
      attestor.setAttestorDebugLevel(_level!);
    }

    attestor.zkOperator = _attestorZkOperator;

    return attestor;
  }

  Future<void> _disposeAttestor(AttestorClient attestor) async {
    _log.info('disposing attestor webview client: $attestor');

    try {
      await attestor.dispose();
    } catch (e, s) {
      _log.severe('Error disposing client', e, s);
    }
  }

  static int _attestorCount = 0;

  @protected
  late final _clientPool = ReusableResourcePool(
    initialPoolSize: 1,
    createResource: () {
      _attestorCount++;
      return _createAttestorWebView('claim-client-$_attestorCount');
    },
    disposeResource: _disposeAttestor,
    ageLimit: const Duration(minutes: 3),
    getResourceAge: AttestorClient.getClientAge,
    isResourceFaulty: (client) => client.isFaulty,
  );

  static int _pathValueAttestorCount = 0;

  late final _pathValuePool = ReusableResourcePool(
    initialPoolSize: 1,
    createResource: () {
      _pathValueAttestorCount++;
      return _createAttestorWebView('pathvalue-client-$_pathValueAttestorCount');
    },
    disposeResource: _disposeAttestor,
    ageLimit: const Duration(minutes: 3),
    getResourceAge: AttestorClient.getClientAge,
    isResourceFaulty: (client) => client.isFaulty,
  );

  List<AttestorClient> get _resources {
    return [..._clientPool.resources, ..._pathValuePool.resources];
  }

  Future<Object?> pingClient({bool isCompute = false}) {
    return useClient(
      (client) async {
        return await client.ping().response;
      },
      timeout: Duration(seconds: 5),
      retryOnTimeout: false,
      isCompute: isCompute,
      canMarkNotResponding: false,
    );
  }

  Future<AttestorProcess<AttestorClaimRequest, List<CreateClaimOutput>>> createClaim(
    Map<String, dynamic> claimRequest, {
    required AttestorClaimOptions options,
    void Function(double progress)? onInitializationProgress,
    AttestorCreateClaimPerformanceReportCallback? onPerformanceReports,

    /// proof generation time can typically take longer on larger data or waiting for circuits to download
    Duration timeoutAfter = const Duration(minutes: 2),
  }) {
    return useClient(
      (attestor) async {
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
      },
      maxAttempts: 3,
      timeout: timeoutAfter,
      retryOnTimeout: false,
      canMarkNotResponding: true,
    );
  }

  String? _level;

  Future<void> setAttestorDebugLevel(String level) {
    _level = level;
    return Future.wait(_resources.map((e) => e.setAttestorDebugLevel(level).response));
  }

  Uri? _attestorUrl;

  Future<void> setAttestorUrl(Uri value) async {
    if (_attestorUrl == value) {
      return;
    }
    _attestorUrl = value;
    _clientPool.disposeResources();
    if (!isLazyInitialized) {
      _clientPool.peekResource;
    }
  }

  AttestorZkOperator? _attestorZkOperator;

  static bool isLazyInitialized = BuildEnv.IS_CLIENT_LAZY_INITIALIZE;

  Future<void> setZkOperator(AttestorZkOperator? operator) async {
    if (_attestorZkOperator == operator) return;
    _attestorZkOperator = operator;
    if (!isLazyInitialized) {
      final r = await peek(isCompute: false);
      r.zkOperator = operator;
    }
  }

  Future<void> ensureReady() async {
    // do nothing
  }

  Future<AttestorClient> peek({bool isCompute = false}) async {
    final pool = isCompute ? _pathValuePool : _clientPool;
    return pool.peekResource;
  }

  Future<T> useClient<T>(
    Future<T> Function(AttestorClient client) fn, {
    required Duration timeout,
    required bool retryOnTimeout,
    bool isCompute = false,
    required bool canMarkNotResponding,
    int maxAttempts = 8,
  }) async {
    final tag = Object().hashCode;
    final log = logging.child('useClient.$tag');
    final pool = isCompute ? _pathValuePool : _clientPool;
    int attempt = 1;
    return retry(
      () {
        log.info('going for attempt: $attempt');
        return pool.compute((client) async {
          log.info('attempt: $attempt with $client');
          try {
            final response = await fn(client).timeout(timeout);
            if (canMarkNotResponding) {
              client.markResponding();
            }
            log.info('success for attempt: $attempt with $client, notRespondingCount:${client.notRespondingCount}');
            return response;
          } on TimeoutException catch (e, s) {
            log.warning('timed out for isCompute: $isCompute, client:$client', e, s);
            if (canMarkNotResponding) {
              client.markNotResponding();
            }
            rethrow;
          }
        });
      },
      maxDelay: Duration(seconds: 5),
      maxAttempts: maxAttempts,
      retryIf: (e) {
        log.warning('failed, attempt: $attempt', e);
        attempt++;
        return e is AttestorWebViewClientReloadException || (retryOnTimeout && e is TimeoutException);
      },
    );
  }

  static const _computeTimeout = Duration(seconds: 20);

  Future<String> extractJSONValueIndex(String json, String jsonPath) {
    return useClient(
      (attestor) {
        return attestor.extractJSONValueIndex(json, jsonPath).response;
      },
      isCompute: true,
      timeout: _computeTimeout,
      retryOnTimeout: true,
      canMarkNotResponding: true,
    );
  }

  Future<String> extractHtmlElement(String html, String xpathExpression) {
    return useClient(
      (attestor) {
        return attestor.extractHtmlElement(html, xpathExpression).response;
      },
      isCompute: true,
      timeout: _computeTimeout,
      retryOnTimeout: true,
      canMarkNotResponding: true,
    );
  }

  Future<Object?> executeJavascript(String js, {required Duration timeout}) {
    return useClient(
      (attestor) {
        return attestor.executeJavascript(js);
      },
      isCompute: true,
      timeout: timeout,
      retryOnTimeout: false,
      canMarkNotResponding: false,
    );
  }

  Future<void> close() {
    return Future.wait([_clientPool.close()]);
  }
}
