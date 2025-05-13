import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:reclaim_flutter_sdk/build_env.dart';
import 'package:reclaim_flutter_sdk/logging/logging.dart';
import 'package:yaml/yaml.dart' as yaml;

// To avoid breaking builds in web
import 'os_web.dart' if (dart.library.io) 'os_io.dart';

Future<String> getReclaimMainSdkVersion() async {
  final logger = logging.child('_getFlutterSdkVersion');
  try {
    final packagePubspec = yaml.loadYaml(await rootBundle.loadString(
      'packages/reclaim_flutter_sdk/pubspec.yaml',
    ));
    final version = packagePubspec['version'];
    return 'v$version';
  } catch (e, s) {
    logger.severe('Failed to get SDK version', e, s);
    return 'unknown';
  }
}

bool isReclaimApp(PackageInfo packageInfo) {
  return switch (packageInfo.packageName) {
    'org.reclaimprotocol.app' => true,
    'org.reclaimprotocol.app.clip' => true,
    _ => false,
  };
}

const _inappModuleIdentifierPrefix = BuildEnv.IS_VERIFIER_INAPP_MODULE ? "inapp_module:" : "";

Future<String> _getSdkConsumerIdentifier() async {
  final packageInfo = await PackageInfo.fromPlatform();
  final clientAppVersion = _getClientAppPackageVersion(packageInfo);
  if (isReclaimApp(packageInfo)) {
    return '$_inappModuleIdentifierPrefix$clientAppVersion';
  }
  final sdkVersion = await getReclaimMainSdkVersion();
  return '${_inappModuleIdentifierPrefix}sdk/$sdkVersion';
}

Completer<String>? _sdkConsumerIdentifierCompleter;

/// For use in UI
Future<String> getSdkConsumerIdentifier() async {
  if (_sdkConsumerIdentifierCompleter == null) {
    final completer = Completer<String>();
    _sdkConsumerIdentifierCompleter = completer;
    try {
      completer.complete(await _getSdkConsumerIdentifier());
    } catch (e) {
      completer.completeError(e);
      final Future<String> gnarkProverFuture = completer.future;
      _sdkConsumerIdentifierCompleter = null;
      return gnarkProverFuture;
    }
  }
  return _sdkConsumerIdentifierCompleter!.future;
}

String _getClientAppPackageVersion(PackageInfo packageInfo) {
  return 'v${packageInfo.version}+${packageInfo.buildNumber}';
}

String _getClientAppInfo(PackageInfo packageInfo) {
  return '(${$getPlatformName()},${packageInfo.packageName}/${_getClientAppPackageVersion(packageInfo)})';
}

Future<String> _getClientSource() async {
  final packageInfo = await PackageInfo.fromPlatform();
  final clientAppInfo = _getClientAppInfo(packageInfo);
  final String sdkIdentifier;
  if (isReclaimApp(packageInfo)) {
    sdkIdentifier = 'verifier-app';
  } else {
    final sdkVersion = await getReclaimMainSdkVersion();
    sdkIdentifier = 'sdk/$sdkVersion';
  }
  return '$_inappModuleIdentifierPrefix$sdkIdentifier $clientAppInfo';
}

Completer<String>? _sourceCompleter;

/// For use in headers and logs for tracking the source
Future<String> getClientSource() async {
  if (_sourceCompleter == null) {
    final completer = Completer<String>();
    _sourceCompleter = completer;
    try {
      completer.complete(await _getClientSource());
    } catch (e) {
      completer.completeError(e);
      final Future<String> gnarkProverFuture = completer.future;
      _sourceCompleter = null;
      return gnarkProverFuture;
    }
  }
  return _sourceCompleter!.future;
}
