import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ui.dart';
import '../constants.dart';
import '../data/identity.dart';
import '../l10n/provider.dart';
import '../logging/logging.dart';
import '../repository/feature_flags.dart';
import '../theme/theme.dart';
import 'verification_review/verification_review.dart';

class PotentialErrorReasonsLearnMoreWidget extends StatefulWidget {
  const PotentialErrorReasonsLearnMoreWidget({super.key, this.textStyle});

  final TextStyle? textStyle;

  @override
  State<PotentialErrorReasonsLearnMoreWidget> createState() => _PotentialErrorReasonsLearnMoreWidgetState();
}

class _PotentialErrorReasonsLearnMoreWidgetState extends State<PotentialErrorReasonsLearnMoreWidget> {
  @override
  void initState() {
    super.initState();
    // pre-load terms
    getFailureReasonsFeatureFlags();
  }

  Future<Uri?> getFailureReasonsFeatureFlags() async {
    final identity = SessionIdentity.latest;

    if (identity == null) return null;

    final log = logging.child('getFailureReasonsFeatureFlags');
    try {
      final repo = FeatureFlagRepository();
      final url = await repo.getFeatureFlag(identity, FeatureFlag.potentialFailureReasonsUrl);
      if (url.trim().isEmpty) return null;
      return Uri.parse(url);
    } catch (e, s) {
      log.warning('Failed to get feature flag', e, s);
    }
    return null;
  }

  void _onSeePotentialFailureReasons(BuildContext context) async {
    final log = logging.child('_onSeePotentialFailureReasons');
    final messenger = ScaffoldMessenger.of(context);
    final reclaimTheme = ReclaimTheme.of(context);
    try {
      final Uri uri =
          reclaimTheme.potentialFailureReasonsUri ??
          (await getFailureReasonsFeatureFlags()) ??
          Uri.parse(ReclaimUrls.POTENTIAL_FAILURE_REASONS_URL);
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
        style: widget.textStyle,
        textAlign: isLargeScreen ? TextAlign.center : TextAlign.start,
      ),
    );
  }
}
