import 'package:flutter/widgets.dart';

import 'models/text_spoiler_configs.dart';
import 'text.dart';

class SpoilerTextSpan extends WidgetSpan {
  SpoilerTextSpan({
    required String text,
    TextSelection? selection,
    super.style,
    super.alignment,
    super.baseline,
    List<InlineSpan>? children,
    bool Function()? canAllowGesture,
    Color? color,
  }) : super(
         child: _SpoilerTextSpanWidget(
           text: text,
           children: children,
           selection: selection,
           style: style,
           canAllowGesture: canAllowGesture,
           color: color,
         ),
       );
}

class _SpoilerTextSpanWidget extends StatelessWidget {
  const _SpoilerTextSpanWidget({
    required this.text,
    required this.children,
    required this.selection,
    required this.style,
    required this.canAllowGesture,
    required this.color,
  });

  final String text;
  final List<InlineSpan>? children;
  final TextSelection? selection;
  final TextStyle? style;
  final bool Function()? canAllowGesture;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textSpans = children?.whereType<TextSpan>();
    final extraTextLength = textSpans?.fold<int>(0, (a, b) => a + (b.text?.length ?? 0)) ?? 0;
    final effectiveTextSelection =
        selection ?? TextSelection(baseOffset: 0, extentOffset: text.length + extraTextLength);
    return SpoilerTextWidget(
      text: text,
      children: children,
      configuration: TextSpoilerConfiguration(
        selection: effectiveTextSelection,
        canAllowGesture: canAllowGesture,
        style: style,
        particleColor: color ?? const Color(0xFF2563EB),
        enableGesture: true,
      ),
    );
  }
}
