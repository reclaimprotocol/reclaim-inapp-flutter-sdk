import 'dart:async';

import 'package:flutter/services.dart' show rootBundle;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:yaml/yaml.dart' as yaml;

import '../../build_env.dart';
import '../../logging/logging.dart';
// To avoid breaking builds in web
import 'os_web.dart' if (dart.library.io) 'os_io.dart';

String? cachedInAppSdkVersion;

Future<String?> getReclaimMainSdkVersionRaw() async {
  final logger = logging.child('getReclaimMainSdkVersionRaw');
  try {
    if (cachedInAppSdkVersion != null) {
      return cachedInAppSdkVersion;
    }
    final packagePubspec = yaml.loadYaml(await rootBundle.loadString('packages/reclaim_inapp_sdk/pubspec.yaml'));
    final version = packagePubspec['version'];
    cachedInAppSdkVersion = version;
    return version;
  } catch (e, s) {
    logger.severe('Failed to get SDK version', e, s);
    return null;
  }
}

String? cachedOperatorVersion;

Future<String?> getOperatorSdkVersionRaw() async {
  final logger = logging.child('getOperatorSdkVersionRaw');
  try {
    if (cachedOperatorVersion != null) {
      return cachedOperatorVersion;
    }
    final packagePubspec = yaml.loadYaml(
      await rootBundle.loadString('packages/reclaim_tee_operator_flutter/pubspec.yaml'),
    );
    final version = packagePubspec['version'];
    cachedOperatorVersion = version;
    return version;
  } catch (e, s) {
    logger.severe('Failed to get operator SDK version', e, s);
    return null;
  }
}

Future<String> getReclaimMainSdkVersion() async {
  final version = await getReclaimMainSdkVersionRaw();
  if (version == null) {
    return 'unknown';
  }
  return 'v$version';
}

Future<String> getOperatorSdkVersion() async {
  final version = await getOperatorSdkVersionRaw();
  if (version == null) {
    return 'unknown';
  }
  return 'v$version';
}

bool isReclaimApp(PackageInfo packageInfo) {
  return switch (packageInfo.packageName) {
    'org.reclaimprotocol.app' => true,
    'org.reclaimprotocol.app.clip' => true,
    _ => false,
  };
}

final _inappModuleIdentifierPrefix = ReclaimEnv.IS_VERIFIER_INAPP_MODULE ? "inapp_module:" : "";

Future<String> _getSdkConsumerIdentifier() async {
  final packageInfo = await PackageInfo.fromPlatform();
  final clientAppVersion = _getClientAppPackageVersion(packageInfo);
  if (isReclaimApp(packageInfo)) {
    return '$_inappModuleIdentifierPrefix$clientAppVersion';
  }
  final sdkVersion = await getReclaimMainSdkVersion();
  final operatorSdkVersion = await getOperatorSdkVersion();
  return '${_inappModuleIdentifierPrefix}sdk/$sdkVersion operator/$operatorSdkVersion';
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

class ClientSource {
  final String source;
  final String version;

  const ClientSource({required this.source, required this.version});

  @override
  String toString() {
    return '$source/$version';
  }

  static ClientSource? current;

  static void setCurrent(ClientSource source) {
    current = source;
    _sourceCompleter = null;
  }
}

Future<String> _getClientSource() async {
  final packageInfo = await PackageInfo.fromPlatform();
  final clientAppInfo = _getClientAppInfo(packageInfo);

  final String sdkIdentifier = await () async {
    final buffer = StringBuffer();

    if (isReclaimApp(packageInfo)) {
      buffer.write('verifier-app ');
    }

    final sdkVersion = await getReclaimMainSdkVersion();
    final operatorSdkVersion = await getOperatorSdkVersion();
    buffer.write('sdk/$sdkVersion operator/$operatorSdkVersion');

    return buffer.toString();
  }();

  final o = StringBuffer();
  o.write(_inappModuleIdentifierPrefix);
  o.write(sdkIdentifier);
  o.write(' $clientAppInfo');
  final clientSource = ClientSource.current;
  if (clientSource != null) {
    o.write(' $clientSource');
  }
  return o.toString();
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
