import 'dart:io';
import 'package:logging/logging.dart';

final _logger = Logger('reclaim_flutter_sdk.platform');

/// Check if the current platform is supported (64-bit runtime)
bool isPlatformSupported() {
  // Check if we are running on a 64-bit runtime
  // Parses the dart runtime platform version string and checks if the build is 64-bit
  final version = Platform.version;
  try {
    final index = version.indexOf('"');
    final lastIndex = version.lastIndexOf('"');
    final versionString = version.substring(index + 1, lastIndex);
    final parts = versionString.split('_');
    if (parts.length < 2) return true; // Default to true if format is unexpected
    final runtimeArch = parts[1];
    return runtimeArch.contains('64');
  } catch (e, s) {
    _logger.warning('Failed to check if platform is supported for runtime version: $version', e, s);
    return true;
  }
}
