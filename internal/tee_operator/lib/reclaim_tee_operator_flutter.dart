// Unified Reclaim Operator library that supports both GNARK (proxy mode) and TEE (TEE mode) operations.
//
// This library provides two operator classes:
// - ReclaimZkOperator: For proxy mode with GNARK-style algorithm initialization
// - ReclaimTEEOperator: For TEE mode with selective algorithm initialization
//
// Both operators use the same native library (libreclaim.so) eliminating symbol conflicts.

// Export common types
export 'package:measure_performance/measure_performance.dart' show PerformanceReport;

// Export operator interfaces
export 'src/common/operator_interface.dart'
    show
        BaseOperator,
        ReclaimProxyOperatorBase,
        ReclaimTEEOperatorBase,
        TEEExecutionResult,
        OnProofPerformanceReportCallback;

// Export GNARK operator and its dependencies
export 'src/gnark_zkoperator/zk_operator.dart' show ReclaimProxyOperator;
export 'src/common/algorithm_initializer.dart'
    show
        KeyAlgorithmAssetUrls,
        ProverAlgorithmAssetUrlsProvider,
        ProverAlgorithmInitializer,
        initializedAlgorithmsNotifier;

// Export common exceptions (shared by both TEE and GNARK)
export 'src/common/exceptions.dart'
    show ReclaimOperatorException, ReclaimNetworkException, ReclaimProofGenerationException, ReclaimValidationException;

// Export TEE operator and its dependencies
export 'src/tee/tee_operator.dart' show ReclaimTEEOperator;
export 'src/tee/models/claim.dart' show ReclaimClaim;
export 'src/tee/models/request_data.dart' show ReclaimRequestData, ResponseMatch, ResponseRedaction;
export 'src/tee/models/client_options.dart' show ClaimCreationClientOptions;

// Export Go library progress stream (for UI progress updates)
// Note: Go logs are automatically bridged to Dart's Logger hierarchy
export 'src/tee/logging/flutter_log_callback.dart' show FlutterZapLogger, ZapLogMessage;

// Export common algorithm types (shared by both operators)
export 'src/common/algorithm/algorithm.dart' show ProverAlgorithmType;
