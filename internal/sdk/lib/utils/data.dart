import 'dart:convert';

import 'package:reclaim_flutter_sdk/logging/logging.dart';

Map<String, String>? processPublicData(Object? publicData) {
  final logger = logging
      .child('ClaimCreationBottomSheetState._LoadingWidget.processPublicData');
  try {
    if (publicData == null || (publicData is Map && publicData.isEmpty)) {
      return null;
    }
    if (publicData is String) {
      publicData = jsonDecode(publicData);
    }
    if (publicData is Map<String, dynamic>) {
      return publicData.map((key, value) => MapEntry(key, value.toString()));
    }
    logger.severe('Unsupported type: ${publicData.runtimeType}');
    return null;
  } catch (e) {
    logger.severe('Error processing publicData: $e');
    return null;
  }
}
