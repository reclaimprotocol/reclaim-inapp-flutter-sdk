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

import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import './extension/rect_x.dart';
import './models/particle.dart';
import './models/string_details.dart';
import './models/text_spoiler_configs.dart';
import './richtext.dart';

class SpoilerTextWidget extends StatefulWidget {
  const SpoilerTextWidget({super.key, required this.text, required this.configuration, this.children});

  final TextSpoilerConfiguration configuration;
  final String text;
  final List<InlineSpan>? children;

  @override
  State createState() => _SpoilerTextWidgetState();
}

class _SpoilerTextWidgetState extends State<SpoilerTextWidget> with TickerProviderStateMixin {
  final rng = Random();
  ui.Image? circleImage;

  AnimationController? fadeAnimationController;
  Animation<double>? fadeAnimation;

  late final AnimationController particleAnimationController;
  late final Animation<double> particleAnimation;
  List<Rect> spoilerRects = [];
  Rect spoilerBounds = Rect.zero;
  final particles = <Particle>[];
  bool enabled = false;

  Offset fadeOffset = Offset.zero;
  Path spoilerPath = Path();

  Particle randomParticle(Rect rect) {
    final offset = rect.deflate(widget.configuration.fadeRadius).randomOffset();

    return Particle(
      offset.dx,
      offset.dy,
      widget.configuration.maxParticleSize,
      widget.configuration.particleColor,
      rng.nextDouble(),
      widget.configuration.speedOfParticles,
      rng.nextDouble() * 2 * pi,
      rect,
    );
  }

  void initializeOffsets(StringDetails details) {
    particles.clear();
    spoilerPath.reset();

    spoilerRects = details.words.map((e) => e.rect.deflate(widget.configuration.fadeRadius)).toList();
    spoilerBounds = spoilerRects.getBounds();

    for (final word in details.words) {
      spoilerPath.addRect(word.rect);

      final count = (word.rect.width + word.rect.height) * widget.configuration.particleDensity;
      for (int index = 0; index < count; index++) {
        particles.add(randomParticle(word.rect));
      }
    }
  }

  @override
  void initState() {
    particleAnimationController = AnimationController(duration: const Duration(seconds: 1), vsync: this);
    particleAnimation = Tween<double>(begin: 0, end: 1).animate(particleAnimationController)..addListener(_myListener);

    if (widget.configuration.fadeAnimation) {
      fadeAnimationController = AnimationController(
        value: enabled ? 0 : 1,
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      fadeAnimation = Tween<double>(begin: 0, end: 1).animate(fadeAnimationController!);
    }

    enabled = widget.configuration.isEnabled;

    if (enabled) {
      particleAnimationController.repeat();
    }

    createCircleImage(color: widget.configuration.particleColor, diameter: widget.configuration.maxParticleSize).then((
      val,
    ) {
      setState(() {
        circleImage = val;
      });
    });

    super.initState();
  }

  void _myListener() {
    setState(() {
      for (int index = 0; index < particles.length; index++) {
        final offset = particles[index];

        // If particle is dead, replace it with a new one
        // Otherwise, move it
        particles[index] = offset.life <= 0.1 ? randomParticle(offset.rect) : offset.moveToRandomAngle();
      }
    });
  }

  @override
  void didUpdateWidget(covariant SpoilerTextWidget oldWidget) {
    if (oldWidget.configuration.selection != widget.configuration.selection ||
        oldWidget.configuration.style != widget.configuration.style) {
      particles.clear();
    }

    if (oldWidget.configuration.isEnabled != widget.configuration.isEnabled) {
      _onEnabledChanged(widget.configuration.isEnabled);
    }

    super.didUpdateWidget(oldWidget);
  }

  void _onEnabledChanged(bool enable) {
    if (enable) {
      setState(() => enabled = true);
      particleAnimationController.repeat();
      fadeAnimationController?.forward();
    } else {
      if (fadeAnimationController == null) {
        stopAnimation();
      } else {
        fadeAnimationController!.toggle().whenCompleteOrCancel(() {
          stopAnimation();
        });
      }
    }
  }

  void stopAnimation() {
    enabled = false;
    particles.clear();

    if (mounted) {
      particleAnimationController.reset();
      setState(() {
        //
      });
    }
  }

  @override
  void dispose() {
    particleAnimation.removeListener(_myListener);
    particleAnimationController.dispose();
    fadeAnimationController?.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    final canAllowGesture = widget.configuration.canAllowGesture;
    final isAllowed = canAllowGesture != null ? canAllowGesture() : true;
    if (!isAllowed) {
      return;
    }

    fadeOffset = details.localPosition;

    if (widget.configuration.enableGesture) {
      final hasSelection = widget.configuration.selection != null;
      if (!hasSelection) {
        setState(() {
          _onEnabledChanged(!enabled);
        });
      } else if (spoilerRects.any((rect) => rect.contains(fadeOffset))) {
        setState(() {
          _onEnabledChanged(!enabled);
        });
      }
    }
  }

  Future<ui.Image> createCircleImage({required double diameter, required Color color}) async {
    assert(diameter.isFinite, 'Diameter cannot be infinite');
    assert(diameter >= 1, 'Diameter must be greater than or equal to 1');

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = color;

    final radius = diameter / 2;
    canvas.drawCircle(Offset.zero, radius, paint);

    final picture = recorder.endRecording();
    return picture.toImage(diameter.toInt(), diameter.toInt());
  }

  void _drawRawAtlas(bool isAnimating, Offset offset, Canvas canvas, double radius) {
    if (circleImage == null) {
      return;
    }

    final int count = particles.length;
    final transforms = Float32List(count * 4);
    final rects = Float32List(count * 4);
    final colors = Int32List(count);

    int index = 0;
    for (final point in particles) {
      final pointWOffset = point + offset;
      final transformIndex = index * 4;

      if (isAnimating) {
        final distance = (fadeOffset - point).distance;

        if (distance < radius) {
          final scale = (distance > radius - 20) ? 1.5 : 1.0;
          final color = (distance > radius - 20) ? Colors.white : point.color;

          // Populate transform data
          transforms[transformIndex] = scale; // scaleX
          transforms[transformIndex + 1] = 0.0; // rotation
          transforms[transformIndex + 2] = pointWOffset.dx; // translateX
          transforms[transformIndex + 3] = pointWOffset.dy; // translateY

          // Populate rect data (assuming the circle texture is square)
          rects[transformIndex] = 0.0; // left
          rects[transformIndex + 1] = 0.0; // top
          rects[transformIndex + 2] = circleImage!.width.toDouble(); // right
          rects[transformIndex + 3] = circleImage!.height.toDouble(); // bottom

          // Populate color data (ARGB format as Int32)
          colors[index] = color.toARGB32();
          index++;
        }
      } else {
        // Populate transform data for non-animating particles
        transforms[transformIndex] = 1.0; // scaleX
        transforms[transformIndex + 1] = 0.0; // rotation
        transforms[transformIndex + 2] = pointWOffset.dx; // translateX
        transforms[transformIndex + 3] = pointWOffset.dy; // translateY

        // Populate rect data (assuming the circle texture is square)
        rects[transformIndex] = 0.0; // left
        rects[transformIndex + 1] = 0.0; // top
        rects[transformIndex + 2] = circleImage!.width.toDouble(); // right
        rects[transformIndex + 3] = circleImage!.height.toDouble(); // bottom

        // Populate color data (ARGB format as Int32)
        colors[index] = point.color.toARGB32();
        index++;
      }
    }

    // Draw all particles in one batch
    canvas.drawRawAtlas(
      circleImage!,
      transforms,
      rects,
      colors,
      BlendMode.srcOver,
      null, // CullRect if needed
      Paint(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.configuration.enableGesture ? _onTapDown : null,
      behavior: HitTestBehavior.translucent,
      child: SpoilerRichText(
        onBoundariesCalculated: initializeOffsets,
        key: UniqueKey(),
        selection: widget.configuration.selection,
        onPaint: (context, offset, superPaint) {
          if (!enabled) {
            superPaint(context, offset);
            return;
          }

          final isAnimating = fadeAnimationController != null && fadeAnimationController!.isAnimating;

          double radius = 0;

          void updateRadius() {
            final farthestPoint = spoilerBounds.getFarthestPoint(fadeOffset);

            final distance = (farthestPoint - (fadeOffset + offset)).distance;

            radius = distance * fadeAnimation!.value;
          }

          if (isAnimating) {
            updateRadius();
          }

          _drawRawAtlas(isAnimating, offset, context.canvas, radius);

          void drawSplashAnimation() {
            final rect = Rect.fromCircle(center: fadeOffset, radius: radius);

            final path = Path.combine(PathOperation.difference, Path()..addRect(spoilerBounds), Path()..addOval(rect));

            context.pushClipPath(true, offset, spoilerBounds, path, superPaint);
          }

          if (isAnimating) {
            drawSplashAnimation();
          }

          if (widget.configuration.selection != null) {
            final path = Path.combine(PathOperation.difference, Path()..addRect(context.estimatedBounds), spoilerPath);

            context.pushClipPath(true, offset, spoilerBounds, path, superPaint);
          }
        },
        initialized: particles.isNotEmpty,
        text: TextSpan(text: widget.text, children: widget.children, style: widget.configuration.style),
      ),
    );
  }
}
