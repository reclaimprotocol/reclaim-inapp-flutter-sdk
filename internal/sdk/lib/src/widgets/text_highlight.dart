import 'package:flutter/widgets.dart';

List<TextSpan> buildTextSpanWithHighlightsForAI(
  String text, {
  required TextStyle style,
  required TextStyle highlightedStyle,
  String highlightStart = r'<highlight>',
  String highlightEnd = r'</highlight>',
}) {
  return buildTextSpanWithHighlights(
    text,
    style: style,
    highlightedStyle: highlightedStyle,
    highlightStart: highlightStart,
    highlightEnd: highlightEnd,
  );
}

typedef TextSpanBuilder = TextSpan Function({required String? text, TextStyle? style});

TextSpan _defaultTextSpanBuilder({required String? text, TextStyle? style}) {
  return TextSpan(text: text, style: style);
}

List<TextSpan> buildTextSpanWithHighlights(
  String text, {
  TextStyle? style,
  required TextStyle highlightedStyle,
  String highlightStart = r'_',
  String highlightEnd = r'_',
  TextSpanBuilder builder = _defaultTextSpanBuilder,
}) {
  final textSpans = <TextSpan>[];
  final regex = RegExp('$highlightStart(.*?)$highlightEnd');
  var lastIndex = 0;

  for (final match in regex.allMatches(text)) {
    // Add text before the highlight tag
    if (match.start > lastIndex) {
      textSpans.add(builder(text: text.substring(lastIndex, match.start), style: style));
    }

    // Add the highlighted text
    textSpans.add(builder(text: match.group(1), style: highlightedStyle));

    lastIndex = match.end;
  }

  // Add any remaining text after the last highlight
  if (lastIndex < text.length) {
    textSpans.add(builder(text: text.substring(lastIndex), style: style));
  }

  return textSpans;
}
