import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../data/app_events.dart';
import '../../widgets/ai_flow_coordinator_widget.dart';

Future<void> handleUserInteraction(List<dynamic> args, InAppWebViewController controller) async {
  final userInteractionData = json.decode(args[0]);
  final interactionType = userInteractionData['eventType'];
  var url = userInteractionData['url'];
  if (url == null) {
    final currentUrl = await controller.getUrl().then((value) => value?.toString());
    if (currentUrl != null && currentUrl.isNotEmpty) {
      url = currentUrl;
    }
  }
  final userInteraction = UserInteractionEvent(interactionType: interactionType, metadata: {'url': url});
  AIFlowCoordinatorWidget.pushEvent(userInteraction);
}
