import 'package:logging/logging.dart';

/// Sentinel string substituted in place of sensitive values when a log
/// record is emitted at INFO or above.
///
/// Kept as a top-level constant so it matches the sentinel used elsewhere
/// in the SDK (see `utils/sanitize.dart`).
const String kRedactedPlaceholder = '[REDACTED]';

/// Returns `true` when a log emitted at [level] should have potentially
/// sensitive values (device IDs, raw claim data, etc.) replaced with
/// [kRedactedPlaceholder] before reaching the log record.
///
/// Rule: redact at `Level.INFO` and above (INFO, WARNING, SEVERE).
/// Lower (`CONFIG`, `FINE`, `FINER`, `FINEST`) is considered dev-facing —
/// those records are gated by the logger's effective level and never
/// leave the device in release builds, so the unredacted values are fine.
///
/// This matches the existing upload-side policy in
/// `lib/src/logging/logging.dart` where `levelValue > Level.FINE.value`
/// triggers `sanitizeLogMessage`.
bool shouldRedactForLevel(Level level) {
  return level >= Level.INFO;
}

/// Convenience for the common INFO-level pattern:
///
/// ```dart
/// logger.info('deviceId: ${redactedAtInfo(deviceId)}');
/// ```
///
/// Always returns `[REDACTED]` — the call site is hardcoded at INFO via
/// `logger.info`, so [shouldRedactForLevel] is trivially true. The helper
/// exists to make the redaction intent explicit and greppable.
String redactedAtInfo(String _) => kRedactedPlaceholder;

/// Returns [value] verbatim when [level] is below INFO, otherwise returns
/// [kRedactedPlaceholder]. Use at call sites whose level is determined at
/// runtime (e.g. inside a helper that forwards `Level`).
String redactIfNeeded(String value, Level level) {
  return shouldRedactForLevel(level) ? kRedactedPlaceholder : value;
}
