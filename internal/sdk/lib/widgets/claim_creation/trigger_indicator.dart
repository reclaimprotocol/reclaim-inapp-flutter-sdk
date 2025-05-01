import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reclaim_flutter_sdk/widgets/claim_creation/claim_creation.dart';

enum ClaimTriggerType {
  // primary colored indicator to indicate that the claim creation is triggered.
  claim,
  // yellow colored indicator to indicate that the intelligence is triggered.
  intelligence,
  // error colored indicator to indicate that the claim creation failed.
  error,
  // none to indicate that the indicator is not visible.
  none,
}

class ClaimTriggerIndicatorController extends ValueNotifier<ClaimTriggerType> {
  ClaimTriggerIndicatorController() : super(ClaimTriggerType.none);

  @protected
  @override
  set value(ClaimTriggerType value) {
    super.value = value;
  }

  void notifyClaim() {
    value = ClaimTriggerType.claim;
  }

  void notifyIntelligence() {
    value = ClaimTriggerType.intelligence;
  }

  Timer? _removeIndicatorTimer;

  void _scheduleRemoveIndicator() {
    _removeIndicatorTimer?.cancel();
    _removeIndicatorTimer = Timer(Durations.extralong4, () {
      // don't use remove because it will do nothing when current value is `error`.
      value = ClaimTriggerType.none;
    });
  }

  void notifyError() {
    value = ClaimTriggerType.error;
    _scheduleRemoveIndicator();
  }

  void remove() {
    // ignore errors, they will be discarded by the timer.
    if (value == ClaimTriggerType.error) return;
    value = ClaimTriggerType.none;
  }
}

class ClaimTriggerIndicator extends StatelessWidget {
  const ClaimTriggerIndicator({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final mediaQuerySize = MediaQuery.sizeOf(context).width * 0.2;

    final indicator = LinearProgressIndicator(
      backgroundColor: Colors.transparent,
      color: color,
      valueColor: AlwaysStoppedAnimation<Color>(color),
      borderRadius: BorderRadiusDirectional.only(
        topStart: Radius.circular(16),
        bottomStart: Radius.circular(16),
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: mediaQuerySize),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: indicator),
          Expanded(child: Transform.flip(flipX: true, child: indicator)),
        ],
      ),
    );
  }
}

class ClaimCreationIndicatorWrapper extends StatelessWidget {
  const ClaimCreationIndicatorWrapper({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = ClaimCreationController.of(context);
    return AnimatedBuilder(
      animation: controller.claimTriggerIndicatorController,
      builder: (context, child) {
        final indicationType = controller.claimTriggerIndicatorController.value;
        Widget indicator;
        switch (indicationType) {
          case ClaimTriggerType.claim:
            indicator = ClaimTriggerIndicator(color: colorScheme.primary);
          case ClaimTriggerType.intelligence:
            indicator = ClaimTriggerIndicator(color: Color(0xffffc636));
          case ClaimTriggerType.error:
            indicator = ClaimTriggerIndicator(color: colorScheme.error);
          case ClaimTriggerType.none:
            return child!;
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [indicator, child!],
        );
      },
      child: child,
    );
  }
}
