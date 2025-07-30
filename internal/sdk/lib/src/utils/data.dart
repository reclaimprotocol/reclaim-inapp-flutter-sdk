import 'dart:convert';

import '../logging/logging.dart';

Map<String, String?>? processPublicData(Object? publicData) {
  final logger = logging.child('ClaimCreationBottomSheetState._LoadingWidget.processPublicData');
  try {
    Object? data = publicData;
    if (data == null) {
      return null;
    }
    if (data is String) {
      try {
        data = json.decode(data);
      } on FormatException catch (_) {
        return {'data': data?.toString()};
      }
    }
    if (data is Map) {
      return {for (final entry in data.entries) entry.key.toString(): json.encode(entry.value)};
    }
    return {'data': data?.toString()};
  } catch (e) {
    logger.severe('Error processing publicData: $e');
    return null;
  }
}
