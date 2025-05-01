import 'dart:async';

import 'package:flutter/material.dart';

/// A widget that changes its child after a given duration.
class ChangingTileBuilder extends StatefulWidget {
  /// The number of tiles to change.
  final int length;

  /// The duration after which the tile will change.
  final Duration duration;

  /// The builder for the tile.
  final IndexedWidgetBuilder builder;

  const ChangingTileBuilder({
    super.key,
    required this.length,
    required this.builder,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<ChangingTileBuilder> createState() => _ChangingTileBuilderState();
}

class _ChangingTileBuilderState extends State<ChangingTileBuilder> {
  Timer? _timer;
  int _currentIndex = 0;

  void _startChange() {
    _timer?.cancel();
    _timer = null;
    _timer = Timer.periodic(widget.duration, increaseIndex);
  }

  @override
  void initState() {
    super.initState();
    _startChange();
  }

  @override
  void didUpdateWidget(covariant ChangingTileBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.length != widget.length && widget.length < oldWidget.length) {
      _timer?.cancel();
      _timer = null;
      _currentIndex = 0;
      _startChange();
    }
  }

  void increaseIndex(_) {
    if (_currentIndex >= widget.length - 1) {
      setState(() {
        _currentIndex = 0;
      });
      return;
    }

    setState(() {
      _currentIndex++;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lastIndex = widget.length - 1;
    if (lastIndex == 0) {
      return const SizedBox();
    }
    return widget.builder(context, _currentIndex.clamp(0, lastIndex));
  }
}
