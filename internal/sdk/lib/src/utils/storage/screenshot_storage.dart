import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../data/screenshot_metadata.dart';
import '../../logging/logging.dart';

/// Storage handler for screenshots and their metadata
class ScreenshotStorage {
  final String sessionId;
  final _logger = logging.child('ScreenshotStorage');

  Directory? _storageDirectory;

  ScreenshotStorage({required this.sessionId});

  /// Get or create the storage directory for screenshots
  Future<Directory> _getStorageDirectory() async {
    if (_storageDirectory != null) {
      return _storageDirectory!;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final screenshotsDir = Directory(path.join(appDir.path, 'screenshots', sessionId));

    if (!screenshotsDir.existsSync()) {
      await screenshotsDir.create(recursive: true);
      _logger.fine('Created screenshots directory: ${screenshotsDir.path}');
    }

    _storageDirectory = screenshotsDir;
    return screenshotsDir;
  }

  /// Save a screenshot with its metadata
  Future<void> saveScreenshot({required ScreenshotMetadata metadata, required Uint8List imageData}) async {
    try {
      final dir = await _getStorageDirectory();

      // Save image file
      final imageFile = File(path.join(dir.path, metadata.filename));
      await imageFile.writeAsBytes(imageData);

      // Save metadata file
      final metadataFile = File(path.join(dir.path, metadata.metadataFilename));
      await metadataFile.writeAsString(json.encode(metadata.toJson()));

      // Clean up old screenshots if we have too many
      await _cleanupOldScreenshots(dir);
    } catch (e, stackTrace) {
      _logger.severe('Failed to save screenshot', e, stackTrace);
      rethrow;
    }
  }

  /// Get all screenshots for a session
  Future<List<ScreenshotMetadata>> getScreenshotsBySession(String sessionId) async {
    try {
      final dir = await _getStorageDirectory();
      final metadataFiles = await dir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();

      final screenshots = <ScreenshotMetadata>[];

      for (final file in metadataFiles) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          screenshots.add(ScreenshotMetadata.fromJson(json));
        } catch (e) {
          _logger.warning('Failed to read metadata file: ${file.path}', e);
        }
      }

      // Sort by timestamp
      screenshots.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      return screenshots;
    } catch (e, stackTrace) {
      _logger.severe('Failed to get screenshots', e, stackTrace);
      return [];
    }
  }

  /// Get screenshot image data by ID
  Future<Uint8List?> getScreenshotData(String screenshotId) async {
    try {
      final dir = await _getStorageDirectory();
      final imageFile = File(path.join(dir.path, '$screenshotId.png'));

      if (imageFile.existsSync()) {
        return await imageFile.readAsBytes();
      }

      return null;
    } catch (e, stackTrace) {
      _logger.severe('Failed to get screenshot data', e, stackTrace);
      return null;
    }
  }

  /// Clear all screenshots for the session
  Future<void> clearSessionScreenshots(String sessionId) async {
    try {
      final dir = await _getStorageDirectory();

      if (dir.existsSync()) {
        await dir.delete(recursive: true);
        _logger.info('Cleared screenshots for session: $sessionId');
      }

      _storageDirectory = null;
    } catch (e, stackTrace) {
      _logger.severe('Failed to clear screenshots', e, stackTrace);
    }
  }

  /// Clean up old screenshots to prevent storage bloat
  Future<void> _cleanupOldScreenshots(Directory dir) async {
    try {
      final files = await dir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.png'))
          .cast<File>()
          .toList();

      // Keep only the most recent 50 screenshots
      const maxScreenshots = 50;

      if (files.length > maxScreenshots) {
        // Sort by modification time
        files.sort((a, b) {
          final aStats = a.statSync();
          final bStats = b.statSync();
          return aStats.modified.compareTo(bStats.modified);
        });

        // Delete oldest files
        final toDelete = files.take(files.length - maxScreenshots);

        for (final file in toDelete) {
          await file.delete();

          // Also delete corresponding metadata file
          final metadataPath = file.path.replaceAll('.png', '.json');
          final metadataFile = File(metadataPath);
          if (metadataFile.existsSync()) {
            await metadataFile.delete();
          }
        }

        _logger.fine('Cleaned up ${toDelete.length} old screenshots');
      }
    } catch (e) {
      _logger.warning('Failed to cleanup old screenshots', e);
    }
  }

  /// Get storage size for the session
  Future<int> getStorageSize() async {
    try {
      final dir = await _getStorageDirectory();

      if (!dir.existsSync()) {
        return 0;
      }

      int totalSize = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      _logger.warning('Failed to calculate storage size', e);
      return 0;
    }
  }

  void dispose() {
    _storageDirectory = null;
  }
}
