import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../data/screenshot_metadata.dart';
import '../logging/logging.dart';
import '../utils/storage/screenshot_storage.dart';
import 'ai_services/ai_client_services.dart';

/// Hybrid service that captures both webview content and Flutter UI overlay
/// This provides complete screenshots showing exactly what the user sees
class HybridScreenshotService {
  final AiServiceClient _aiServiceClient;
  final ScreenshotStorage _storage;
  final String sessionId;
  final String providerId;

  Timer? _captureTimer;
  InAppWebViewController? _webViewController;
  GlobalKey? _appKey;
  bool _isCapturing = false;
  int _screenshotCounter = 0;

  static const Duration _defaultCaptureInterval = Duration(seconds: 5);
  static const int _maxScreenshotsPerSession = 300;

  final _logger = logging.child('HybridScreenshotService');

  HybridScreenshotService({
    required AiServiceClient aiServiceClient,
    required this.sessionId,
    required this.providerId,
    ScreenshotStorage? storage,
  }) : _aiServiceClient = aiServiceClient,
       _storage = storage ?? ScreenshotStorage(sessionId: sessionId);

  /// Start periodic screenshot capturing with both webview and app UI
  void startCapturing({
    required InAppWebViewController webViewController,
    required GlobalKey appKey,
    Duration interval = _defaultCaptureInterval,
  }) {
    if (_isCapturing) {
      return;
    }

    _logger.info('Starting hybrid screenshot capture with interval: ${interval.inSeconds}s');
    _webViewController = webViewController;
    _appKey = appKey;
    _isCapturing = true;
    _screenshotCounter = 0;

    // Capture initial screenshot immediately
    _captureHybridScreenshot();

    // Set up periodic capture
    _captureTimer = Timer.periodic(interval, (_) {
      if (_screenshotCounter >= _maxScreenshotsPerSession) {
        _logger.warning('Maximum screenshots reached, stopping capture');
        stopCapturing();
        return;
      }
      _captureHybridScreenshot();
    });
  }

  /// Stop screenshot capturing
  void stopCapturing() {
    _logger.info('Stopping hybrid screenshot capture');
    _captureTimer?.cancel();
    _captureTimer = null;
    _isCapturing = false;
    _webViewController = null;
    _appKey = null;
  }

  /// Update the webview controller (useful when webview is recreated)
  void updateWebViewController(InAppWebViewController? controller) {
    _logger.info('Updating webview controller');
    _webViewController = controller;
  }

  /// Update the app key (useful when UI structure changes)
  void updateAppKey(GlobalKey? key) {
    _logger.info('Updating app key');
    _appKey = key;
  }

  /// Capture both webview content and app UI
  Future<void> _captureHybridScreenshot() async {
    if (!_isCapturing) return;

    try {
      // Get current URL and page title from webview
      String? url;
      String? title;
      Uint8List? appUIScreenshot;
      Uint8List? webviewScreenshot;
      bool appUICaptured = false;

      // First, capture webview content (without UI overlay)
      if (_webViewController != null) {
        try {
          url = (await _webViewController!.getUrl())?.toString();
          title = await _webViewController!.getTitle();

          // Capture webview content
          webviewScreenshot = await _webViewController!.takeScreenshot();
        } catch (e) {
          _logger.warning('Failed to capture webview content: $e');
        }
      }

      // Try to capture the full app UI (including overlays, dialogs, etc.)
      if (_appKey?.currentContext != null) {
        try {
          final RenderObject? renderObject = _appKey!.currentContext?.findRenderObject();

          // Check if the render object is valid and attached
          if (renderObject != null && renderObject.attached) {
            // First check if it's actually a RenderRepaintBoundary
            if (renderObject is! RenderRepaintBoundary) {
              _logger.warning('Render object is not a RenderRepaintBoundary, it is: ${renderObject.runtimeType}');
              _logger.fine('Render object not a valid boundary for screenshot');
              return;
            }

            final RenderRepaintBoundary boundary = renderObject;

            // In release mode, debugNeedsPaint is always false, so we shouldn't check it
            // Add a small delay to ensure the boundary is ready
            await Future.delayed(const Duration(milliseconds: 50));

            try {
              final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
              final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

              if (byteData != null) {
                final appScreenshot = byteData.buffer.asUint8List();

                // Only use app screenshot if it's not empty and appears valid
                if (appScreenshot.isNotEmpty && appScreenshot.length > 5000) {
                  bool hasContent = _hasVisibleContent(appScreenshot);

                  if (hasContent) {
                    appUIScreenshot = appScreenshot;
                    appUICaptured = true;
                  } else {
                    _logger.fine('App UI screenshot appears blank');
                  }
                } else {
                  _logger.fine('App UI screenshot too small');
                }
              } else {
                _logger.warning('Failed to convert image to byte data');
              }

              // Dispose the image to free memory
              image.dispose();
            } catch (imageError, imageStack) {
              _logger.severe('Error during image capture/conversion', imageError, imageStack);
              // Check if it's the late initialization error
              if (imageError.toString().contains('LateInitializationError')) {
                _logger.warning('Late initialization error detected - boundary may not be ready');
              }
            }
          } else {
            _logger.fine('Render object not attached or is null');
          }
        } catch (e, stackTrace) {
          _logger.warning('Failed to capture app UI: $e');
          _logger.fine('Stack trace: $stackTrace');
        }
      } else {
        _logger.fine('App key context is null');
      }

      // Skip if we have no screenshots at all
      if (webviewScreenshot == null && appUIScreenshot == null) {
        _logger.warning('Failed to capture any screenshot data');
        return;
      }

      _screenshotCounter++;

      final timestamp = DateTime.now();
      final baseId = '${sessionId}_$_screenshotCounter';

      // Send the app UI screenshot (or webview if app UI not available)
      if (appUIScreenshot != null && appUICaptured) {
        final appMetadata = ScreenshotMetadata(
          id: '${baseId}_ui',
          sessionId: sessionId,
          providerId: providerId,
          timestamp: timestamp,
          url: url?.isNotEmpty == true ? url! : 'app://hybrid-view',
          pageTitle: title?.isNotEmpty == true ? title! : 'UI View $_screenshotCounter',
          screenshotNumber: _screenshotCounter,
          additionalData: {
            'screenType': 'app_ui',
            'captureMethod': 'app_ui_with_overlay',
            'hasWebviewPair': webviewScreenshot != null,
            'webviewPairId': webviewScreenshot != null ? '${baseId}_webview' : null,
          },
        );

        // Store and send app UI screenshot
        await _storage.saveScreenshot(metadata: appMetadata, imageData: appUIScreenshot);

        await _sendScreenshotToAIService(metadata: appMetadata, imageData: appUIScreenshot);
      }

      // Always send webview screenshot if available
      if (webviewScreenshot != null) {
        final webviewMetadata = ScreenshotMetadata(
          id: '${baseId}_webview',
          sessionId: sessionId,
          providerId: providerId,
          timestamp: timestamp,
          url: url?.isNotEmpty == true ? url! : 'app://webview',
          pageTitle: title?.isNotEmpty == true ? title! : 'WebView $_screenshotCounter',
          screenshotNumber: _screenshotCounter,
          additionalData: {
            'screenType': 'webview_only',
            'captureMethod': 'webview_content',
            'hasUIPair': appUICaptured,
            'uiPairId': appUICaptured ? '${baseId}_ui' : null,
            'isPrimaryView': !appUICaptured, // This is the primary view if no UI captured
          },
        );

        // Store and send webview screenshot
        await _storage.saveScreenshot(metadata: webviewMetadata, imageData: webviewScreenshot);

        await _sendScreenshotToAIService(metadata: webviewMetadata, imageData: webviewScreenshot);
      }
    } catch (e, stackTrace) {
      _logger.severe('Error capturing hybrid screenshot', e, stackTrace);
    }
  }

  /// Capture screenshot on demand (e.g., on specific events)
  Future<ScreenshotMetadata?> captureOnDemand({required String eventType, Map<String, dynamic>? additionalData}) async {
    if (_webViewController == null && _appKey == null) {
      _logger.warning('Cannot capture on-demand screenshot: no controllers available');
      return null;
    }

    try {
      String? url;
      String? title;
      Uint8List? screenshotData;

      // Try webview capture
      if (_webViewController != null) {
        try {
          url = (await _webViewController!.getUrl())?.toString();
          title = await _webViewController!.getTitle();
          screenshotData = await _webViewController!.takeScreenshot();
        } catch (e) {
          _logger.warning('Webview capture failed: $e');
        }
      }

      // Try app UI capture
      if (_appKey?.currentContext != null) {
        try {
          final RenderRepaintBoundary? boundary = _appKey!.currentContext?.findRenderObject() as RenderRepaintBoundary?;

          if (boundary != null) {
            final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
            final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

            if (byteData != null) {
              final appScreenshot = byteData.buffer.asUint8List();
              if (appScreenshot.isNotEmpty) {
                screenshotData = appScreenshot;
              }
            }
          }
        } catch (e) {
          _logger.warning('App UI capture failed: $e');
        }
      }

      if (screenshotData == null) {
        _logger.warning('Failed to capture on-demand screenshot');
        return null;
      }

      final metadata = ScreenshotMetadata(
        id: '${sessionId}_hybrid_ondemand_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: sessionId,
        providerId: providerId,
        timestamp: DateTime.now(),
        url: url?.isNotEmpty == true ? url! : 'app://hybrid-view',
        pageTitle: title?.isNotEmpty == true ? title! : 'On-Demand: $eventType',
        eventType: eventType,
        additionalData: {...?additionalData, 'screenType': 'hybrid', 'captureMethod': 'on_demand'},
      );

      // Store locally
      await _storage.saveScreenshot(metadata: metadata, imageData: screenshotData);

      // Send to AI service
      await _sendScreenshotToAIService(metadata: metadata, imageData: screenshotData);

      return metadata;
    } catch (e, stackTrace) {
      _logger.severe('Error capturing on-demand hybrid screenshot', e, stackTrace);
      return null;
    }
  }

  /// Send screenshot to AI worker flow service
  Future<void> _sendScreenshotToAIService({required ScreenshotMetadata metadata, required Uint8List imageData}) async {
    try {
      await _aiServiceClient.uploadScreenshot(metadata: metadata, imageData: imageData);
    } catch (e) {
      _logger.severe('Failed to send screenshot to AI service', e);
      // Don't throw - we still have it stored locally
    }
  }

  /// Get all screenshots for the current session
  Future<List<ScreenshotMetadata>> getSessionScreenshots() async {
    return await _storage.getScreenshotsBySession(sessionId);
  }

  /// Get screenshot by ID
  Future<Uint8List?> getScreenshotData(String screenshotId) async {
    return await _storage.getScreenshotData(screenshotId);
  }

  /// Clear all screenshots for the session
  Future<void> clearSessionScreenshots() async {
    await _storage.clearSessionScreenshots(sessionId);
  }

  /// Dispose of resources
  void dispose() {
    stopCapturing();
    _storage.dispose();
  }

  /// Check if an image has visible content (not all transparent or white)
  bool _hasVisibleContent(Uint8List imageData) {
    // Simple heuristic: check file size and entropy
    // A blank or transparent image will typically be very small when compressed
    // or have very low entropy in the data

    if (imageData.length < 5000) {
      return false; // Too small to have meaningful content
    }

    // Sample a few bytes to check for variation
    // If all sampled bytes are the same, it's likely a blank image
    const sampleSize = 100;
    const step = 1000;

    if (imageData.length < step * sampleSize) {
      return true; // Can't sample enough, assume it has content
    }

    int? firstByte;
    for (int i = 0; i < sampleSize; i++) {
      final byte = imageData[i * step];
      if (firstByte == null) {
        firstByte = byte;
      } else if (byte != firstByte) {
        return true; // Found variation, has content
      }
    }

    return false; // All sampled bytes are the same, likely blank
  }

  bool get isCapturing => _isCapturing;
  int get screenshotCount => _screenshotCounter;
}
