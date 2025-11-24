import 'package:flutter/widgets.dart';

import '../../../utils/observable_notifier.dart';
import 'view.dart';

class PopupWindowState {
  const PopupWindowState({this.isVisible = false, this.parameters});

  final bool isVisible;
  final WebViewWindowParameters? parameters;

  PopupWindowState copyWith({bool? isVisible, WebViewWindowParameters? parameters}) {
    return PopupWindowState(isVisible: isVisible ?? this.isVisible, parameters: parameters ?? this.parameters);
  }
}

class PopupWindowController extends ObservableNotifier<PopupWindowState> {
  PopupWindowController() : super(const PopupWindowState());

  Widget wrap({required Widget child}) {
    return _Provider(notifier: this, child: child);
  }

  void showPopup(WebViewWindowParameters parameters) {
    value = PopupWindowState(isVisible: true, parameters: parameters);
  }

  void hidePopup() {
    value = const PopupWindowState(isVisible: false);
  }

  static PopupWindowController readOf(BuildContext context) {
    final widget = context.getInheritedWidgetOfExactType<_Provider>();
    assert(widget != null, 'No PopupWindowController provider found in the widget tree.');
    return widget!.notifier!;
  }

  static PopupWindowController of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<_Provider>();
    assert(widget != null, 'No PopupWindowController provider found in the widget tree.');
    return widget!.notifier!;
  }
}

class _Provider extends InheritedNotifier<PopupWindowController> {
  const _Provider({required super.notifier, required super.child});
}
