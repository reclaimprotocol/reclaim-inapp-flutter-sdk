enum TimelineEventSeverity {
  info,
  warning,
  error,
  success;

  String toJson() => name;
}

class TimelineEventResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final String? error;

  TimelineEventResponse({required this.success, required this.message, this.data, this.error});

  factory TimelineEventResponse.fromJson(Map<String, dynamic> json) {
    return TimelineEventResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
      error: json['error'] as String?,
    );
  }
}
