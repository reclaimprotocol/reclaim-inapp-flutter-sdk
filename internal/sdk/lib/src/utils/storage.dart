import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../logging/logging.dart';

final _logger = logging.child('ReclaimStorage');

class ReclaimStorage {
  final FlutterSecureStorage storage;

  const ReclaimStorage([FlutterSecureStorage? storage])
    : storage = storage ?? const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));

  Future<void> saveData(String key, String value) async {
    final logger = _logger.child('saveData');
    try {
      await storage.write(key: key, value: value);
    } catch (e, s) {
      logger.warning("Warning: could not save data for $key to secure storage", e, s);
    }
  }

  Future<String> getData(String key) async {
    final logger = _logger.child('getData');
    try {
      final String? value = await storage.read(key: key);
      if (value == null) {
        return '';
      }
      return value;
    } catch (e, s) {
      logger.severe("Error getting data from secure storage", e, s);
      return '';
    }
  }
}
