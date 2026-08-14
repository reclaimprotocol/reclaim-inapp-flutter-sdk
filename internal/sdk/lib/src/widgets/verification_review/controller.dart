import 'package:equatable/equatable.dart';
import 'package:material_ui/material_ui.dart';

import '../../utils/observable_notifier.dart';

class VerificationReviewState with Equatable {
  final bool isVisible;

  const VerificationReviewState({this.isVisible = true});

  VerificationReviewState copyWith({bool? isVisible}) {
    return VerificationReviewState(isVisible: isVisible ?? this.isVisible);
  }

  @override
  List<Object?> get props => [isVisible];
}

class VerificationReviewController extends ObservableNotifier<VerificationReviewState> {
  VerificationReviewController() : super(const VerificationReviewState());

  VoidCallback? onExtendNoActivity;

  Widget wrap({required Widget child}) {
    return _Provider(notifier: this, child: child);
  }

  void setIsVisible(bool isVisible) {
    value = value.copyWith(isVisible: isVisible);
  }

  void notifyActivity() {
    onExtendNoActivity?.call();
  }

  static VerificationReviewController readOf(BuildContext context) {
    final widget = context.getInheritedWidgetOfExactType<_Provider>();
    assert(
      widget != null,
      'No VerificationReviewController provider found in the widget tree. Ensure you are using [VerificationReviewController.wrap] in an ancestor to provider the [VerificationReviewController].',
    );
    return widget!.notifier!;
  }

  static VerificationReviewController of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<_Provider>();
    assert(
      widget != null,
      'No VerificationReviewController provider found in the widget tree. Ensure you are using [VerificationReviewController.wrap] in an ancestor to provider the [VerificationReviewController].',
    );
    return widget!.notifier!;
  }
}

class _Provider extends InheritedNotifier<VerificationReviewController> {
  const _Provider({required super.child, required VerificationReviewController super.notifier});

  @override
  bool updateShouldNotify(covariant _Provider oldWidget) {
    return oldWidget.notifier?.value != notifier?.value;
  }
}
