import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../ui.dart';
import '../../controller.dart';
import '../../widgets/safe_area.dart';
import 'view.dart';

const verificationViewRouteSettings = RouteSettings(name: 'reclaim-verification');

/// A [PageRoute] that builds a [VerificationView].
///
/// Based on [MaterialPageRoute]
class VerificationViewPageRoute extends PageRoute<dynamic> with CupertinoRouteTransitionMixin<dynamic> {
  VerificationViewPageRoute({required this.verificationController})
    : maintainState = true,
      title = null,
      super(
        settings: verificationViewRouteSettings,
        allowSnapshotting: true,
        barrierDismissible: false,
        fullscreenDialog: true,
      ) {
    assert(opaque);
  }

  final VerificationController verificationController;

  /// Builds the primary contents of the route.
  @override
  Widget buildContent(BuildContext context) {
    return verificationController.wrap(
      child: ReclaimThemeProvider(
        child: MediaQuery.fromView(
          view: View.of(context),
          child: FractionallyPaddedSafeArea(
            top: false,
            bottomFraction: Theme.of(context).platform == TargetPlatform.iOS
                // Eyeballed on iphone that ~32% of safe area bottom padding should be safe
                ? 0.32
                // Androids always provide bottom padding as 0.
                : 1,
            child: VerificationView(),
          ),
        ),
      ),
    );
  }

  @override
  final bool maintainState;

  @override
  final String? title;

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}
