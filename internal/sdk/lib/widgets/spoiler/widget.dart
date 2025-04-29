import 'package:flutter/material.dart';
import 'package:reclaim_flutter_sdk/widgets/spoiler/text_span.dart';

String _handleLargeText(final String text) {
  // TODO: change this with a way to limit length using available width
  if (text.length <= 26) return text;
  return '${text.substring(0, 23)}...';
}

class HashedValueSpoilerTextSpan extends WidgetSpan {
  final String value;
  final String? realValue;

  HashedValueSpoilerTextSpan({
    required this.value,
    required this.realValue,
    required super.style,
  }) : super(
         child: HashedValueTextSpanWidget(
           value: _handleLargeText(value),
           realValue: realValue == null ? null : _handleLargeText(realValue),
           style: style,
         ),
       );
}

class HashedValueTextSpanWidget extends StatefulWidget {
  const HashedValueTextSpanWidget({
    super.key,
    required this.value,
    required this.realValue,
    required this.style,
  });

  final String value;
  final String? realValue;
  final TextStyle? style;

  @override
  State<HashedValueTextSpanWidget> createState() =>
      _HashedValueTextSpanWidgetState();
}

enum _HashedValueRevealType { unrevealed, displayUnsharedValue, displayHash }

class _HashedValueTextSpanWidgetState extends State<HashedValueTextSpanWidget> {
  _HashedValueRevealType _revealType = _HashedValueRevealType.unrevealed;

  String get text {
    switch (_revealType) {
      case _HashedValueRevealType.unrevealed:
      case _HashedValueRevealType.displayUnsharedValue:
        return widget.realValue ?? widget.value;
      case _HashedValueRevealType.displayHash:
        return widget.value;
    }
  }

  bool _isGestureAllowed() {
    if (widget.realValue == null || widget.realValue == widget.value) {
      return true;
    }
    final previous = _revealType;
    switch (_revealType) {
      case _HashedValueRevealType.unrevealed:
        if (widget.realValue != null) {
          _revealType = _HashedValueRevealType.displayUnsharedValue;
        } else {
          _revealType = _HashedValueRevealType.displayHash;
        }
        break;
      case _HashedValueRevealType.displayUnsharedValue:
        _revealType = _HashedValueRevealType.displayHash;
        break;
      case _HashedValueRevealType.displayHash:
        _revealType = _HashedValueRevealType.unrevealed;
        break;
    }

    if (widget.realValue != null &&
        _revealType == _HashedValueRevealType.unrevealed) {
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
    const defaultTextStyle = TextStyle(
      color: Color(0xFF2563EB),
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );

    final effectiveTextStyle = widget.style ?? defaultTextStyle;

    final infoTextStyle = effectiveTextStyle.merge(
      const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
    );

    final realValue = widget.realValue;

    return Text.rich(
      SpoilerTextSpan(
        text: text,
        canAllowGesture: _isGestureAllowed,
        children: [
          if (realValue != null)
            TextSpan(
              text:
                  _revealType != _HashedValueRevealType.displayHash
                      ? ' (not shared)'
                      // for a better transition to the spoiler, we add text of same length that's shown when witness value is present and revealed
                      : '             ',
              style: infoTextStyle,
            ),
        ],
        style: effectiveTextStyle,
      ),
    );
  }
}
