import 'package:permission_handler/permission_handler.dart';
import '../logging/logging.dart';

/// Requests permissions and logs errors silently
Future<void>
    requestPermission(
  Permission
      permission,
) async {
  final logger =
      logging.child('requestPermission');
  try {
    await permission
        .request();
  } catch (e, s) {
    logger
        .severe(
      'Failed to request permission [${permission.value}]',
      e,
      s,
    );
  }
}
