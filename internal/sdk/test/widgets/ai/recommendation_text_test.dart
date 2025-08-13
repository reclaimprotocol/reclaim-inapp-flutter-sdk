import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim_inapp_sdk/src/widgets/ai/recommendation_text.dart';

void main() {
  group('RecommendationText', () {
    testWidgets('renders plain text without highlights correctly', (WidgetTester tester) async {
      const text = 'This is a plain text';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RecommendationText(text: text)),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;
      final textSpans = textSpan.children as List<TextSpan>;
      expect(textSpans.length, equals(1));
      expect(textSpans[0].text, equals(text));
      expect(textSpans[0].style?.color, equals(Colors.black));
    });

    testWidgets('renders text with single highlight correctly', (WidgetTester tester) async {
      const text = 'This is a <highlight>highlighted</highlight> text';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RecommendationText(text: text)),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;
      final textSpans = textSpan.children as List<TextSpan>;

      expect(textSpans.length, equals(3));
      expect(textSpans[0].text, equals('This is a '));
      expect(textSpans[0].style?.color, equals(Colors.black));
      expect(textSpans[1].text, equals('highlighted'));
      expect(textSpans[1].style?.color, equals(Colors.blue));
      expect(textSpans[2].text, equals(' text'));
      expect(textSpans[2].style?.color, equals(Colors.black));
    });

    testWidgets('renders text with multiple highlights correctly', (WidgetTester tester) async {
      const text = 'This is a <highlight>highlighted</highlight> text with <highlight>another</highlight> highlight';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RecommendationText(text: text)),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;
      final textSpans = textSpan.children as List<TextSpan>;

      expect(textSpans.length, equals(5));
      expect(textSpans[0].text, equals('This is a '));
      expect(textSpans[0].style?.color, equals(Colors.black));
      expect(textSpans[1].text, equals('highlighted'));
      expect(textSpans[1].style?.color, equals(Colors.blue));
      expect(textSpans[2].text, equals(' text with '));
      expect(textSpans[2].style?.color, equals(Colors.black));
      expect(textSpans[3].text, equals('another'));
      expect(textSpans[3].style?.color, equals(Colors.blue));
      expect(textSpans[4].text, equals(' highlight'));
      expect(textSpans[4].style?.color, equals(Colors.black));
    });

    testWidgets('renders text with highlight at start correctly', (WidgetTester tester) async {
      const text = '<highlight>Highlighted</highlight> text at start';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RecommendationText(text: text)),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;
      final textSpans = textSpan.children as List<TextSpan>;

      expect(textSpans.length, equals(2));
      expect(textSpans[0].text, equals('Highlighted'));
      expect(textSpans[0].style?.color, equals(Colors.blue));
      expect(textSpans[1].text, equals(' text at start'));
      expect(textSpans[1].style?.color, equals(Colors.black));
    });

    testWidgets('renders text with highlight at end correctly', (WidgetTester tester) async {
      const text = 'Text at end <highlight>highlighted</highlight>';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RecommendationText(text: text)),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;
      final textSpans = textSpan.children as List<TextSpan>;

      expect(textSpans.length, equals(2));
      expect(textSpans[0].text, equals('Text at end '));
      expect(textSpans[0].style?.color, equals(Colors.black));
      expect(textSpans[1].text, equals('highlighted'));
      expect(textSpans[1].style?.color, equals(Colors.blue));
    });
  });
}
