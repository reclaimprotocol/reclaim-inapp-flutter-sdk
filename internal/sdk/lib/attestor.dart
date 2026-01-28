import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:reclaim_tee_operator_flutter/reclaim_tee_operator_flutter.dart';
import 'package:retry/retry.dart';

import 'src/attestor/attestor.dart';
import 'src/attestor/client/native/client.dart';
import 'src/build_env.dart';
import 'src/constants.dart';
import 'src/data/create_claim.dart';
import 'src/logging/logging.dart';
import 'src/utils/reusable_resource_pool.dart';

export 'src/attestor/attestor.dart';

class Attestor {
  Attestor() {
    initializedAlgorithmsNotifier.addListener(() {
      _log.info('initialized algorithms: ${initializedAlgorithmsNotifier.value}');
    });
  }

  static final instance = Attestor();

  static final _log = logging.child('Attestor');

  bool _useTeeOperator = false; // Default to WebView, user can enable TEE

  /// Get current TEE operator usage status
  bool get useTeeOperator => _useTeeOperator;

  /// Enable or disable TEE operator for claim creation
  /// When enabled, claims will be created using native TEE execution
  /// When disabled, claims will use the WebView-based approach
  void setUseTeeOperator(bool enable) {
    if (_useTeeOperator == enable) return;

    _useTeeOperator = enable;
    _log.info('TEE operator usage ${enable ? "enabled" : "disabled"}');
  }

  AttestorJsClient _createAttestorWebView(String debugLabel) {
    _log.info('creating attestor webview client: $debugLabel');

    final effectiveUrl = _attestorUrl ?? Uri.parse(ReclaimUrls.DEFAULT_ATTESTOR_WEB_URL);
    _attestorUrl = effectiveUrl;

    final attestor = AttestorWebViewClient(attestorBrowserRpcUrl: effectiveUrl, debugLabel: debugLabel);

    if (_level != null) {
      try {
        attestor.setAttestorDebugLevel(_level!);
      } catch (e) {
        _log.severe('Error setting attestor debug level', e);
      }
    }

    _log.fine('attestor client created');

    return attestor;
  }

  Future<void> _disposeAttestor(AttestorJsClient attestor) async {
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
    getResourceAge: AttestorJsClient.getClientAge,
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
    getResourceAge: AttestorJsClient.getClientAge,
    isResourceFaulty: (client) => client.isFaulty,
  );

  List<AttestorJsClient> get _resources {
    return [..._clientPool.resources, ..._pathValuePool.resources];
  }

  Future<AttestorProcess<AttestorClaimRequest, List<CreateClaimOutput>>> createClaim(
    Map<String, dynamic> claimRequest, {
    required AttestorClaimOptions options,
    void Function(double progress)? onInitializationProgress,
    AttestorCreateClaimPerformanceReportCallback? onPerformanceReports,

    /// proof generation time can typically take longer on larger data or waiting for circuits to download
    Duration timeoutAfter = const Duration(minutes: 2),
  }) async {
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

  static bool isLazyInitialized = BuildEnv.IS_CLIENT_LAZY_INITIALIZE;

  Future<void> ensureReady() async {
    if (useTeeOperator) {
      return AttestorTeeClient.instance.ensureReady();
    } else {
      final r = await peek(isCompute: false);
      return r.ensureReady();
    }
  }

  Future<AttestorJsClient> peek({bool isCompute = false}) async {
    final pool = isCompute ? _pathValuePool : _clientPool;
    return pool.peekResource;
  }

  Future<T> useClient<T>(
    Future<T> Function(AttestorPlatform client) fn, {
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

    FutureOr<T> onClient(AttestorPlatform client) async {
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
    }

    return retry(
      () {
        if (_useTeeOperator) {
          return onClient(AttestorTeeClient.instance);
        }
        log.fine('going for attempt: $attempt');
        return pool.compute((client) async {
          log.fine('attempt: $attempt with $client');
          try {
            final response = await fn(client).timeout(timeout);
            if (canMarkNotResponding) {
              client.markResponding();
            }
            log.fine('success for attempt: $attempt with $client, notRespondingCount:${client.notRespondingCount}');
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
      maxDelay: const Duration(seconds: 5),
      maxAttempts: maxAttempts,
      retryIf: (e) {
        log.warning('failed, attempt: $attempt', e);
        attempt++;
        return e is AttestorClientReloadException || (retryOnTimeout && e is TimeoutException);
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

  Future<void> close() {
    return Future.wait([_clientPool.close()]);
  }

  Future<bool> isPlatformSupported() async {
    if (useTeeOperator) {
      return AttestorTeeClient.instance.isPlatformSupported();
    } else {
      final r = await peek(isCompute: false);
      return r.isPlatformSupported();
    }
  }
}
