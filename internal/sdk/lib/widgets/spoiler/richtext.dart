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

import 'package:flutter/rendering.dart'
    show DiagnosticPropertiesBuilder, DiagnosticsProperty, TextSelection;
import 'package:flutter/widgets.dart'
    show BuildContext, Directionality, RichText, ValueSetter;
import './models/string_details.dart';
import './widgets/spoiler_paragraph.dart';

class SpoilerRichText extends RichText {
  final bool initialized;
  final ValueSetter<StringDetails> onBoundariesCalculated;
  final PaintCallback? onPaint;
  final TextSelection? selection;

  SpoilerRichText({
    required this.onBoundariesCalculated,
    required this.initialized,
    this.onPaint,
    this.selection,
    super.key,
    required super.text,
  });

  @override
  SpoilerParagraph createRenderObject(BuildContext context) {
    return SpoilerParagraph(
      text,
      onPaint: onPaint,
      selection: selection,
      onBoundariesCalculated: onBoundariesCalculated,
      initialized: initialized,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('initialized', initialized));
    properties.add(DiagnosticsProperty<ValueSetter<StringDetails>>(
        'onBoundariesCalculated', onBoundariesCalculated));
    properties.add(DiagnosticsProperty<PaintCallback?>('onPaint', onPaint));
  }
}