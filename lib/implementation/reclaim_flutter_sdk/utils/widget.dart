import 'package:flutter/widgets.dart';

T? findChildWidgetByType<
        T extends Widget>(
    BuildContext
        element) {
  T? targetWidget;
  element.visitChildElements(
      (element) {
    final widget =
        element.widget;
    if (widget
        is T) {
      targetWidget =
          widget;
    } else {
      targetWidget =
          findChildWidgetByType(element);
    }
  });
  return targetWidget;
}
