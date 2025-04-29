import 'package:flutter/material.dart';
import '../constants.dart';

class TextWithColoredSpans
    extends StatelessWidget {
  final String
      text;

  const TextWithColoredSpans(
      {super.key,
      required this.text});

  List<TextSpan>
      _splitString(String text) {
    List<TextSpan>
        spans =
        [];
    var templateStringChunks =
        text.split(templateParamRegex);
    var paramNames = templateParamRegex
        .allMatches(text)
        .toList();
    while (
        templateStringChunks.isNotEmpty) {
      spans.add(TextSpan(text: templateStringChunks.removeAt(0)));
      if (paramNames.isNotEmpty) {
        var value = paramNames.removeAt(0);
        spans.add(TextSpan(text: value.input.substring(value.start + 2, value.end - 2), style: const TextStyle(color: Color(0xFF332FED))));
      }
    }
    return spans;
  }

  @override
  Widget build(
      BuildContext
          context) {
    return RichText(
      text:
          TextSpan(
        style: const TextStyle(color: Colors.black),
        children: _splitString(text),
      ),
    );
  }
}
