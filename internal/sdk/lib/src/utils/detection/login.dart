import '../../data/web_context.dart';
import '../../logging/logging.dart';

bool requiresLoginInteraction(WebContext context) {
  final logger = logging.child('requiresLoginInteraction');
  logger.info('requiresLoginInteraction: ${!context.isLoggedIn}');
  return !context.isLoggedIn;
}

bool potentiallyLoggedIn(WebContext context, String currentUrl) {
  if (context.aiFlowDone) return false;
  final lastInputUrl = context.lastInputUrl;
  final logger = logging.child('potentiallyLoggedIn');
  logger.info('url: $currentUrl, lastInputUrl: $lastInputUrl');
  return currentUrl != lastInputUrl && lastInputUrl.isNotEmpty;
}
