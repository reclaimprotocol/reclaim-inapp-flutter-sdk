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

import 'dart:math' hide log;
import 'dart:ui' show Color, Offset, Rect;

/// Particle class to represent a single particle
///
/// This class is used to represent a single particle in the particle system.
/// It contains the position, size, color, life, speed, angle, and rect of the particle.
class Particle extends Offset {
  /// The size of the particle.
  final double size;

  /// The color of the particle.
  final Color color;

  /// Value between 0 and 1 representing the life of the particle.
  final double life;

  /// Value representing the speed of the particle in pixels per frame.
  final double speed;

  /// Value representing the angle of the particle in radians.
  final double angle;

  /// The rect where the particle is located.
  final Rect rect;

  const Particle(
    super.dx,
    super.dy,
    this.size,
    this.color,
    this.life,
    this.speed,
    this.angle,
    this.rect,
  );

  /// Copy the particle with new values
  Particle copyWith({
    double? dx,
    double? dy,
    double? size,
    Color? color,
    double? life,
    double? speed,
    double? angle,
    Rect? rect,
  }) {
    return Particle(
      dx ?? this.dx,
      dy ?? this.dy,
      size ?? this.size,
      color ?? this.color,
      life ?? this.life,
      speed ?? this.speed,
      angle ?? this.angle,
      rect ?? this.rect,
    );
  }

  /// Move the particle
  ///
  /// This method is used to move the particle.
  /// It calculates the next position of the particle based on the current position, speed, and angle.
  Particle moveToRandomAngle() {
    return moveWithAngle(angle).copyWith(
      // Random angle
      angle: angle + (Random().nextDouble() - 0.5),
    );
  }

  Particle moveWithAngle(double angle) {
    final next = this + Offset.fromDirection(angle, speed);

    final lifetime = life - 0.01;
    // final opacity = lifetime > 1 ? lifetime - 1 : lifetime;

    final color = lifetime > .1
        ? this.color.withValues(alpha: lifetime.clamp(0, 1))
        : this.color;

    return copyWith(
      dx: next.dx,
      dy: next.dy,
      life: lifetime,
      color: color,
      // Given angle
      angle: angle,
    );
  }
}
