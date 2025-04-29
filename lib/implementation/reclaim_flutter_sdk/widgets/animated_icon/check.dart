import 'dart:ui';
import 'package:flutter/material.dart';

class DataSharedCheckAnimatedIcon
    extends StatefulWidget {
  final double?
      height;
  const DataSharedCheckAnimatedIcon(
      {super.key,
      required this.height});

  @override
  State<DataSharedCheckAnimatedIcon>
      createState() =>
          DataSharedCheckAnimatedIconState();
}

class DataSharedCheckAnimatedIconState
    extends State<
        DataSharedCheckAnimatedIcon>
    with
        TickerProviderStateMixin {
  late final AnimationController
      _icon1Controller =
      AnimationController(
    vsync:
        this,
    duration:
        const Duration(milliseconds: 700),
  );
  late final AnimationController
      _icon2Controller =
      AnimationController(
    vsync:
        this,
    duration:
        const Duration(milliseconds: 400),
  );

  late final Animation<double>
      _icon1Animation =
      Tween<double>(
    begin:
        0,
    end:
        1,
  ).animate(
    CurvedAnimation(
        parent: _icon1Controller,
        curve: Curves.easeInOutCirc),
  );
  late final Animation<double>
      _icon2Animation =
      Tween<double>(
    begin:
        0,
    end:
        1,
  ).animate(
    CurvedAnimation(
        parent: _icon2Controller,
        curve: Curves.easeInOutCirc),
  );

  void
      startAnimation() async {
    await Future.delayed(
        const Duration(milliseconds: 100));
    if (mounted) {
      _icon1Controller.forward();
    }
    await Future.delayed(
        const Duration(milliseconds: 400));
    if (mounted) {
      _icon2Controller.forward();
    }
  }

  void
      reset() {
    _icon1Controller
        .reset();
    _icon2Controller
        .reset();
  }

  @override
  void
      initState() {
    super
        .initState();
    Future.microtask(
        startAnimation);
  }

  @override
  void
      dispose() {
    _icon1Controller
        .dispose();
    _icon2Controller
        .dispose();
    super
        .dispose();
  }

  @override
  Widget build(
      BuildContext
          context) {
    final double
        dimension =
        widget.height?.clamp(0, 160.0) ?? 140.0;
    final double
        strokeWidth =
        dimension * 0.07;
    final double
        distance =
        9.0;
    return Stack(
      alignment:
          Alignment.center,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(end: strokeWidth + distance),
          child: AnimatedCheck(
            progress: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: _icon1Animation, curve: Curves.easeInOut),
            ),
            size: dimension,
            color: Colors.black,
            strokeWidth: strokeWidth,
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(start: strokeWidth + distance),
          child: AnimatedCheck(
            progress: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: _icon2Animation, curve: Curves.easeInOut),
            ),
            size: dimension,
            color: Color(0xFF0000EE),
            strokeWidth: strokeWidth,
          ),
        ),
      ],
    );
  }
}

class AnimatedCheck
    extends StatefulWidget {
  final Animation<double>
      progress;

  // The size of the checkmark
  final double
      size;

  // The primary color of the checkmark
  final Color?
      color;

  // The width of the checkmark stroke
  final double?
      strokeWidth;

  const AnimatedCheck({
    super.key,
    required this.progress,
    required this.size,
    this.color,
    this.strokeWidth,
  });

  @override
  State<StatefulWidget>
      createState() =>
          _AnimatedCheckState();
}

class _AnimatedCheckState
    extends State<
        AnimatedCheck>
    with
        SingleTickerProviderStateMixin {
  @override
  void
      initState() {
    super
        .initState();
  }

  @override
  Widget build(
      BuildContext
          context) {
    final ThemeData
        theme =
        Theme.of(context);

    return CustomPaint(
      foregroundPainter:
          AnimatedPathPainter(
        widget.progress,
        widget.color ?? theme.primaryColor,
        widget.strokeWidth,
      ),
      child:
          SizedBox(width: widget.size, height: widget.size),
    );
  }
}

class AnimatedPathPainter
    extends CustomPainter {
  final Animation<double>
      _animation;

  final Color
      _color;

  final double?
      strokeWidth;

  AnimatedPathPainter(
      this._animation,
      this._color,
      this.strokeWidth)
      : super(repaint: _animation);

  Path _createAnyPath(
      Size
          size) {
    return Path()
      ..moveTo(0.27083 * size.width,
          0.54167 * size.height)
      ..lineTo(0.41667 * size.width,
          0.68750 * size.height)
      ..lineTo(0.75000 * size.width,
          0.35417 * size.height);
  }

  Path createAnimatedPath(
      Path
          originalPath,
      double
          animationPercent) {
    final totalLength = originalPath
        .computeMetrics()
        .fold(
          0.0,
          (double prev, PathMetric metric) => prev + metric.length,
        );

    final currentLength =
        totalLength * animationPercent;

    return extractPathUntilLength(
        originalPath,
        currentLength);
  }

  Path extractPathUntilLength(
      Path
          originalPath,
      double
          length) {
    var currentLength =
        0.0;

    final path =
        Path();

    var metricsIterator = originalPath
        .computeMetrics()
        .iterator;

    while (
        metricsIterator.moveNext()) {
      var metric =
          metricsIterator.current;

      var nextLength =
          currentLength + metric.length;

      final isLastSegment =
          nextLength > length;
      if (isLastSegment) {
        final remainingLength = length - currentLength;
        final pathSegment = metric.extractPath(0.0, remainingLength);

        path.addPath(pathSegment, Offset.zero);
        break;
      } else {
        final pathSegment = metric.extractPath(0.0, metric.length);
        path.addPath(pathSegment, Offset.zero);
      }

      currentLength =
          nextLength;
    }

    return path;
  }

  @override
  void paint(
      Canvas
          canvas,
      Size
          size) {
    final animationPercent =
        _animation.value;

    final path = createAnimatedPath(
        _createAnyPath(size),
        animationPercent);

    final Paint
        paint =
        Paint();
    paint.color =
        _color;
    paint.style =
        PaintingStyle.stroke;
    paint.strokeWidth =
        strokeWidth ?? size.width * 0.06;

    canvas.drawPath(
        path,
        paint);
  }

  @override
  bool shouldRepaint(
      CustomPainter
          oldDelegate) {
    return true;
  }
}
