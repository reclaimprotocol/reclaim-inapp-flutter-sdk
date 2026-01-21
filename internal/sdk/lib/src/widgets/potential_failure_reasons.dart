import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ui.dart';
import '../constants.dart';
import '../l10n/provider.dart';
import '../logging/logging.dart';
import '../theme/theme.dart';
import 'verification_review/verification_review.dart';

class PotentialErrorReasonsLearnMoreWidget extends StatelessWidget {
  const PotentialErrorReasonsLearnMoreWidget({super.key, this.textStyle});

  final TextStyle? textStyle;

  void _onSeePotentialFailureReasons(BuildContext context) async {
    final log = logging.child('_onSeePotentialFailureReasons');
    final messenger = ScaffoldMessenger.of(context);
    final reclaimTheme = ReclaimTheme.of(context);
    try {
      final uri = reclaimTheme.potentialFailureReasonsUri ?? Uri.parse(ReclaimUrls.POTENTIAL_FAILURE_REASONS_URL);
      final stopwatch = Stopwatch()..start();
      final didLaunch = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      stopwatch.stop();

      if (didLaunch || stopwatch.elapsed > const Duration(seconds: 2)) {
        return;
      }
    } catch (e, s) {
      log.severe('Failed to launch potential failure reasons website', e, s);
    }
    messenger.showSnackBar(const SnackBar(content: Text('Contact application support for more information.')));
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.sizeOf(context).width > VerificationReviewPageSurface.smallScreenWidthExtent;
    final highlightColor = Theme.brightnessOf(context) == Brightness.light ? Colors.indigo : Colors.amber;

    return FontsLoaded(
      child: Text.rich(
        TextSpan(
          children: buildTextSpanWithHighlights(
            context.l10n.forMoreInformationAboutThisError,
            highlightedStyle: TextStyle(color: highlightColor, decoration: TextDecoration.underline),
            builder: ({style, text}) {
              return TextSpan(
                text: text,
                style: style,
                // Moving this to parent textspan doesn't work
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    _onSeePotentialFailureReasons(context);
                  },
              );
            },
          ),
        ),
        style: textStyle,
        textAlign: isLargeScreen ? TextAlign.center : TextAlign.start,
      ),
    );
  }
}
