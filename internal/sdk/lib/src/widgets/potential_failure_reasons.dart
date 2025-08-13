import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../logging/logging.dart';
import 'fonts_loaded.dart';
import 'verification_review/verification_review.dart';

class PotentialErrorReasonsLearnMoreWidget extends StatelessWidget {
  const PotentialErrorReasonsLearnMoreWidget({super.key, this.textStyle});

  final TextStyle? textStyle;

  void _onSeePotentialFailureReasons(BuildContext context) async {
    final log = logging.child('_onSeePotentialFailureReasons');
    final messenger = ScaffoldMessenger.of(context);
    try {
      final stopwatch = Stopwatch()..start();
      final didLaunch = await launchUrl(
        Uri.parse(ReclaimUrls.POTENTIAL_FAILURE_REASONS_URL),
        mode: LaunchMode.inAppBrowserView,
      );
      stopwatch.stop();

      if (didLaunch || stopwatch.elapsed > const Duration(seconds: 2)) {
        return;
      }
    } catch (e, s) {
      log.severe('Failed to launch potential failure reasons website', e, s);
    }
    messenger.showSnackBar(SnackBar(content: Text('Contact application support for more information.')));
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.sizeOf(context).width > VerificationReviewPageSurface.smallScreenWidthExtent;

    return FontsLoaded(
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: "For more information about this error, please "),
            TextSpan(
              text: "see potential failure reasons.",
              style: TextStyle(color: Colors.indigo, decoration: TextDecoration.underline),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  _onSeePotentialFailureReasons(context);
                },
            ),
          ],
        ),
        style: textStyle,
        textAlign: isLargeScreen ? TextAlign.center : TextAlign.start,
      ),
    );
  }
}
