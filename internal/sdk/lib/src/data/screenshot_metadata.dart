import 'package:json_annotation/json_annotation.dart';

part 'screenshot_metadata.g.dart';

/// Metadata for a captured screenshot during AI provider verification
@JsonSerializable()
class ScreenshotMetadata {
  final String id;
  final String sessionId;
  final String providerId;
  final DateTime timestamp;
  final String url;
  final String pageTitle;
  final int? screenshotNumber;
  final String? eventType;
  final Map<String, dynamic>? additionalData;

  ScreenshotMetadata({
    required this.id,
    required this.sessionId,
    required this.providerId,
    required this.timestamp,
    required this.url,
    required this.pageTitle,
    this.screenshotNumber,
    this.eventType,
    this.additionalData,
  });

  factory ScreenshotMetadata.fromJson(Map<String, dynamic> json) => _$ScreenshotMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$ScreenshotMetadataToJson(this);

  /// Create a filename for storing the screenshot
  String get filename => '$id.png';

  /// Create a metadata filename
  String get metadataFilename => '$id.json';
}
