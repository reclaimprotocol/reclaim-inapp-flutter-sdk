import 'dart:async';

import 'package:flutter/services.dart'
    show
        rootBundle;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:yaml/yaml.dart'
    as yaml;

import '../../build_env.dart';
import '../../logging/logging.dart';
// To avoid breaking builds in web
import 'os_web.dart'
    if (dart.library.io) 'os_io.dart';

Future<String>
    getReclaimFlutterSdkVersion() async {
  final logger =
      logging.child('_getFlutterSdkVersion');
  try {
    final packagePubspec =
        yaml.loadYaml(await rootBundle.loadString(
      'packages/reclaim_flutter_sdk/pubspec.yaml',
    ));
    return packagePubspec[
        'version'];
  } catch (e, s) {
    logger.severe(
        'Failed to get SDK version',
        e,
        s);
    return 'unknown';
  }
}

bool isReclaimApp(
    PackageInfo
        packageInfo) {
  return switch (
      packageInfo.packageName) {
    'org.reclaimprotocol.app' =>
      true,
    'org.reclaimprotocol.app.clip' =>
      true,
    _ =>
      false,
  };
}

const _inappModuleIdentifierPrefix = BuildEnv
        .IS_VERIFIER_INAPP_MODULE
    ? "inapp_module:"
    : "";

Future<String>
    _getSdkConsumerIdentifier() async {
  final packageInfo =
      await PackageInfo.fromPlatform();
  final clientAppVersion =
      _getClientAppPackageVersion(packageInfo);
  if (isReclaimApp(
      packageInfo)) {
    return '$_inappModuleIdentifierPrefix$clientAppVersion';
  }
  final sdkVersion =
      await getReclaimFlutterSdkVersion();
  return '${_inappModuleIdentifierPrefix}sdk:v$sdkVersion';
}

Completer<
        String>?
    _sdkConsumerIdentifierCompleter;

Future<String>
    getSdkConsumerIdentifier() async {
  if (_sdkConsumerIdentifierCompleter ==
      null) {
    final completer =
        Completer<String>();
    _sdkConsumerIdentifierCompleter =
        completer;
    try {
      completer.complete(await _getSdkConsumerIdentifier());
    } catch (e) {
      completer.completeError(e);
      final Future<String>
          gnarkProverFuture =
          completer.future;
      _sdkConsumerIdentifierCompleter =
          null;
      return gnarkProverFuture;
    }
  }
  return _sdkConsumerIdentifierCompleter!
      .future;
}

String _getClientAppPackageVersion(
    PackageInfo
        packageInfo) {
  return 'v${packageInfo.version}+${packageInfo.buildNumber}';
}

String _getClientAppInfo(
    PackageInfo
        packageInfo) {
  return '${_getClientAppPackageVersion(packageInfo)}(${$getPlatformName()},${packageInfo.packageName})';
}

Future<String>
    _getClientSource() async {
  final packageInfo =
      await PackageInfo.fromPlatform();
  final clientAppInfo =
      _getClientAppInfo(packageInfo);
  if (isReclaimApp(
      packageInfo)) {
    return '${_inappModuleIdentifierPrefix}flutter-app:$clientAppInfo';
  }
  final sdkVersion =
      await getReclaimFlutterSdkVersion();
  return '${_inappModuleIdentifierPrefix}flutter-sdk:v${sdkVersion}_$clientAppInfo';
}

Completer<
        String>?
    _sourceCompleter;

Future<String>
    getClientSource() async {
  if (_sourceCompleter ==
      null) {
    final completer =
        Completer<String>();
    _sourceCompleter =
        completer;
    try {
      completer.complete(await _getClientSource());
    } catch (e) {
      completer.completeError(e);
      final Future<String>
          gnarkProverFuture =
          completer.future;
      _sourceCompleter =
          null;
      return gnarkProverFuture;
    }
  }
  return _sourceCompleter!
      .future;
}
