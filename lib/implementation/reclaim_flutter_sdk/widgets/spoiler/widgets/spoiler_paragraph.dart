/// Source code copied and modified from https://github.com/zhukeev/spoiler_widget of package https://pub.dev/packages/spoiler_widget
/// MIT License
///
/// Copyright (c) 2024 Zhukeev Argen
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in all
/// copies or substantial portions of the Software.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
/// SOFTWARE.

import 'package:flutter/rendering.dart';

import '../models/string_details.dart';

typedef PaintCallback
    = void
        Function(
  PaintingContext
      context,
  Offset
      offset,
  void Function(PaintingContext context,
          Offset offset)
      superPaint,
);

class SpoilerParagraph
    extends RenderParagraph {
  final bool
      initialized;
  final ValueSetter<StringDetails>
      onBoundariesCalculated;
  final PaintCallback?
      onPaint;
  final TextSelection?
      selection;

  SpoilerParagraph(
    super.text, {
    required super.textDirection,
    required this.onBoundariesCalculated,
    this.onPaint,
    this.selection,
    required this.initialized,
  });

  /// Get list of words bounding boxes
  List<Word>
      getWords() {
    final text =
        this.text;
    final textPainter =
        TextPainter(
      text:
          text,
      textDirection:
          textDirection,
      textAlign:
          textAlign,
      // textScaler: textScaler ,
      maxLines:
          maxLines,
      locale:
          locale,
      strutStyle:
          strutStyle,
    );
    textPainter
        .layout(
      minWidth:
          constraints.minWidth,
      maxWidth:
          constraints.maxWidth,
    );

    // Get all text runs from text
    final textRuns =
        <Word>[];

    void getAllWordBoundaries(
        int offset,
        List<Word> list) {
      final range =
          textPainter.getWordBoundary(TextPosition(offset: offset));

      if (range.isCollapsed)
        return;

      final substr =
          text.toPlainText().substring(range.start, range.end);

      /// Move to next word if current word is empty
      if (substr.trim().isEmpty) {
        getAllWordBoundaries(range.end, list);
        return;
      }

      // Get paragraph position
      final pos =
          textPainter.getBoxesForSelection(TextSelection(baseOffset: range.start, extentOffset: range.end));

      if (pos.isNotEmpty) {
        textRuns.add(Word(word: substr, rect: pos.first.toRect(), range: range));
      }

      getAllWordBoundaries(range.end,
          list);
    }

    if (selection !=
        null) {
      final boxes =
          textPainter.getBoxesForSelection(selection!);

      for (final box
          in boxes) {
        textRuns.add(
          Word(
            word: text.toPlainText().substring(selection!.start, selection!.end),
            rect: box.toRect(),
            range: TextRange(start: selection!.start, end: selection!.end),
          ),
        );
      }
    } else {
      getAllWordBoundaries(0,
          textRuns);
    }
    return textRuns;
  }

  @override
  void paint(
      PaintingContext
          context,
      Offset
          offset) {
    if (!initialized) {
      final bounds =
          getWords();

      onBoundariesCalculated(StringDetails(
          words: bounds,
          offset: offset));
    }

    onPaint?.call(
        context,
        offset,
        super.paint);
  }
}
