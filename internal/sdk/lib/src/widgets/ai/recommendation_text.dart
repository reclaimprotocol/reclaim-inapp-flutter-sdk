import 'package:flutter/material.dart';

import '../text_highlight.dart';
export '../text_highlight.dart';

class RecommendationText extends StatelessWidget {
  final String text;

  const RecommendationText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final textSpans = buildTextSpanWithHighlightsForAI(
      text,
      style: const TextStyle(color: Colors.black),
      highlightedStyle: const TextStyle(color: Colors.blue),
    );

    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(children: textSpans),
      ),
    );
  }
}
