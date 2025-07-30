import 'package:permission_handler/permission_handler.dart';

import '../logging/logging.dart';

class PermissionService {
  final logger = logging.child('PermissionService');

  /// Requests permissions and logs errors silently
  Future<PermissionStatus> _requestPermission(Permission permission) async {
    final logger = logging.child('requestPermission');
    try {
      return await permission.request();
    } catch (e, s) {
      logger.severe('Failed to request permission [${permission.value}]', e, s);
    }
    return PermissionStatus.denied;
  }

  Future<List<PermissionStatus>> _requestPermissions(List<Permission> permissions) async {
    final logger = logging.child('requestPermission');
    try {
      final result = await permissions.request();
      return result.values.map((status) => status).toList();
    } catch (e, s) {
      logger.severe('Failed to request permission [${permissions.map((p) => p.value).join(', ')}]', e, s);
    }
    return permissions.map((p) => PermissionStatus.denied).toList();
  }

  Future<bool> requestGeolocationPermission() async {
    final log = logger.child('_onGeolocationPermissionsShowPrompt');
    try {
      await _requestPermission(Permission.location);
      await _requestPermission(Permission.locationWhenInUse);
      await _requestPermission(Permission.locationAlways);
      final status = await Permission.location.status;
      final isDenied = status.isDenied || status.isPermanentlyDenied;
      return !isDenied;
    } catch (e, s) {
      log.severe('Failed to request location permissions', e, s);
    }
    return false;
  }

  Future<bool> requestCameraPermission() async {
    final status = await _requestPermission(Permission.camera);
    return status.isGranted;
  }

  Future<bool> requestMicrophonePermission() async {
    final status = await _requestPermission(Permission.microphone);
    return status.isGranted;
  }

  Future<bool> requestCameraAndMicrophonePermission() async {
    final result = await _requestPermissions([Permission.camera, Permission.microphone]);
    return result.every((status) => status.isGranted);
  }

  Future<bool> openAppLocationSettings() {
    return openAppSettings();
  }
}
