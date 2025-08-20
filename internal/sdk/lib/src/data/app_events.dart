import 'package:meta/meta.dart';

import 'http_request_log.dart';

/// Base class for all application events triggering AI flows.
/// Sealed classes ensure a known, finite set of event subtypes.
sealed class AppEvent {
  final DateTime timestamp;

  AppEvent() : timestamp = DateTime.now();

  @override
  String toString() => 'AppEvent(timestamp: ${timestamp.toIso8601String()})';

  @mustCallSuper
  Map<String, dynamic> toJson() {
    return {'timestamp': timestamp.toIso8601String()};
  }
}

final class PageLoadedEvent extends AppEvent {
  final String url;

  final String renderedDom;
  final String? formData;

  PageLoadedEvent({required this.url, required this.renderedDom, this.formData});

  @override
  String toString() => 'PageLoadedEvent(url: $url, renderedDom: $renderedDom, formData: $formData)';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['url'] = url;
    json['renderedDom'] = renderedDom;
    json['metadata'] = {'formData': formData};
    return json;
  }
}

enum InteractionType { click, scroll, input, submit, other }

final class UserInteractionEvent extends AppEvent {
  final InteractionType interactionType;
  final Map<String, dynamic>? metadata;

  UserInteractionEvent({required String interactionType, this.metadata})
    : interactionType = InteractionType.values.firstWhere(
        (type) => type.name == interactionType.toLowerCase(),
        orElse: () => InteractionType.other,
      );

  @override
  String toString() => 'UserInteractionEvent(interactionType: $interactionType, metadata: $metadata)';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['interactionType'] = interactionType.name;
    json['metadata'] = metadata;
    return json;
  }
}

final class NetworkRequestEvent extends AppEvent {
  final RequestLog requestLog;

  NetworkRequestEvent({required this.requestLog});

  @override
  String toString() => 'NetworkRequestEvent(requestLog: $requestLog)';

  @override
  Map<String, dynamic> toJson() {
    final requestLogJson = requestLog.toJson();
    final json = super.toJson();
    json.addAll(requestLogJson);
    return json;
  }
}

final class ClaimCreationFailedEvent extends AppEvent {
  final String errorMessage;
  final String requestHash;
  final String? stackTrace;

  ClaimCreationFailedEvent({required this.errorMessage, required this.requestHash, this.stackTrace});

  @override
  String toString() =>
      'ClaimCreationFailedEvent(errorMessage: $errorMessage, stackTrace: $stackTrace, requestHash: $requestHash)';

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['errorMessage'] = errorMessage;
    json['stackTrace'] = stackTrace;
    json['requestHash'] = requestHash;
    return json;
  }
}
