import 'dart:async';
import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../logging/logging.dart';
import 'webview_state_mixin.dart';

Future<void> setWebViewSettingsWith(
  InAppWebViewController controller,
  FutureOr<InAppWebViewSettings?> Function(InAppWebViewSettings) update,
) async {
  final log = logging.child('setWebViewSettingsWith');
  final currentSettings = ((await controller.getSettings()) ?? defaultWebViewSettings).copy();
  log.fine(() => 'old webview settings: ${json.encode(currentSettings)}');
  final newSettings = await update(currentSettings);
  if (newSettings == null) {
    return;
  }
  log.fine(() => 'Setting webview settings: ${json.encode(newSettings)}');
  await controller.setSettings(settings: newSettings);
}
