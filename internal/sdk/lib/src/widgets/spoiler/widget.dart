import 'package:flutter/material.dart';
import 'text_span.dart';

String _handleLargeText(final String text) {
  // TODO: change this with a way to limit length using available width
  if (text.length <= 26) return text;
  return '${text.substring(0, 23)}...';
}

class HashedValueSpoilerTextSpan extends WidgetSpan {
  final String value;
  final String? realValue;

  HashedValueSpoilerTextSpan({required this.value, required this.realValue, required super.style})
    : super(
        child: HashedValueTextSpanWidget.handleLargeText(value: value, realValue: realValue, style: style),
      );
}

class HashedValueTextSpanWidget extends StatefulWidget {
  const HashedValueTextSpanWidget({super.key, required this.value, required this.realValue, required this.style});
  HashedValueTextSpanWidget.handleLargeText({
    super.key,
    required String value,
    required String? realValue,
    required this.style,
  }) : value = _handleLargeText(value),
       realValue = realValue == null ? null : _handleLargeText(realValue);

  final String value;
  final String? realValue;
  final TextStyle? style;

  @override
  State<HashedValueTextSpanWidget> createState() => _HashedValueTextSpanWidgetState();
}

enum _HashedValueRevealType { unrevealed, displayUnsharedValue, displayHash }

class _HashedValueTextSpanWidgetState extends State<HashedValueTextSpanWidget> {
  _HashedValueRevealType _revealType = _HashedValueRevealType.unrevealed;

  String get text {
    switch (_revealType) {
      case _HashedValueRevealType.unrevealed:
      case _HashedValueRevealType.displayUnsharedValue:
        final realValue = widget.realValue;
        if (realValue != null) {
          return realValue;
        }
        break;
      case _HashedValueRevealType.displayHash:
        break;
    }
    // This unicode character is on purpose, it's a better looking asterisk than the regular one
    return List.filled(widget.value.length, '∗').join();
  }

  bool _isGestureAllowed() {
    if (widget.realValue == null || widget.realValue == widget.value) {
      return true;
    }
    final previous = _revealType;
    switch (_revealType) {
      case _HashedValueRevealType.unrevealed:
        _revealType = _HashedValueRevealType.displayUnsharedValue;
        break;
      case _HashedValueRevealType.displayUnsharedValue:
        _revealType = _HashedValueRevealType.displayHash;
        break;
      case _HashedValueRevealType.displayHash:
        _revealType = _HashedValueRevealType.unrevealed;
        break;
    }

    if (widget.realValue != null && _revealType == _HashedValueRevealType.unrevealed) {
      // we delay the reveal to make the transition smoother when transitioning from hashed value to spoiler view
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {});
        }
      });
    } else {
      setState(() {});
    }

    return previous != _HashedValueRevealType.displayUnsharedValue;
  }

  @override
  Widget build(BuildContext context) {
    const defaultTextStyle = TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 14);

    final effectiveTextStyle = widget.style ?? defaultTextStyle;

    final infoTextStyle = effectiveTextStyle.merge(const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal));

    return Text.rich(
      SpoilerTextSpan(
        text: text,
        canAllowGesture: _isGestureAllowed,
        children: [
          TextSpan(
            text: _revealType != _HashedValueRevealType.displayHash
                ? ' (not shared)'
                // for a better transition to the spoiler, we add text of same length that's shown when witness value is present and revealed
                : '             ',
            style: infoTextStyle,
          ),
        ],
        style: effectiveTextStyle,
      ),
      maxLines: 1,
    );
  }
}
