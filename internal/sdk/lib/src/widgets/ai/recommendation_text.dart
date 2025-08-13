import 'package:flutter/material.dart';

List<TextSpan> parseHighlightedText(String text, TextStyle normalStyle, TextStyle highlightedStyle) {
  final textSpans = <TextSpan>[];
  final regex = RegExp(r'<highlight>(.*?)</highlight>');
  var lastIndex = 0;

  for (final match in regex.allMatches(text)) {
    // Add text before the highlight tag
    if (match.start > lastIndex) {
      textSpans.add(TextSpan(text: text.substring(lastIndex, match.start), style: normalStyle));
    }

    // Add the highlighted text
    textSpans.add(TextSpan(text: match.group(1), style: highlightedStyle));

    lastIndex = match.end;
  }

  // Add any remaining text after the last highlight
  if (lastIndex < text.length) {
    textSpans.add(TextSpan(text: text.substring(lastIndex), style: normalStyle));
  }

  return textSpans;
}

class RecommendationText extends StatelessWidget {
  final String text;

  const RecommendationText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final textSpans = parseHighlightedText(
      text,
      const TextStyle(color: Colors.black),
      const TextStyle(color: Colors.blue),
    );

    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(children: textSpans),
      ),
    );
  }
}
