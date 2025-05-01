import 'package:flutter/widgets.dart';

import 'claim_creation.dart';

class ClaimCreationControllerProvider
    extends InheritedNotifier<ClaimCreationController> {
  const ClaimCreationControllerProvider({
    super.key,
    required this.controller,
    required super.child,
  }) : super(notifier: controller);

  final ClaimCreationController controller;
}

class ClaimCreationScope extends StatefulWidget {
  const ClaimCreationScope({
    super.key,
    required this.uiDelegateOptions,
    required this.controller,
    required this.child,
  });

  final ClaimCreationUIDelegateOptions uiDelegateOptions;
  final ClaimCreationController controller;
  final Widget child;

  @override
  State<ClaimCreationScope> createState() => _ClaimCreationState();
}

class _ClaimCreationState extends ClaimCreationUIDelegate {
  @override
  late final ClaimCreationUIDelegateOptions claimCreationUIDelegateOptions =
      widget.uiDelegateOptions;

  @override
  Widget build(BuildContext context) {
    return ClaimCreationControllerProvider(
      controller: widget.controller,
      child: widget.child,
    );
  }
}
