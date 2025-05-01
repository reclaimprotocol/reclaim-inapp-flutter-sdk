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

import 'dart:ui';

import 'package:flutter/foundation.dart' show immutable;

/// Configuration for the spoiler widget
/// [particleDensity] is the density of the particles / count of particles
/// [speedOfParticles] is the speed of the particles
/// [particleColor] is the color of the particles
/// [maxParticleSize] is the maximum size of the particles
/// [fadeAnimation] is whether to fade the particles
/// [fadeRadius] is the radius of the fade effect
/// [isEnabled] is whether the spoiler is enabled
/// [enableGesture] is whether to enable gesture to reveal the spoiler
@immutable
class SpoilerConfiguration {
  final double particleDensity;
  final double speedOfParticles;
  final Color particleColor;
  final double maxParticleSize;
  final bool fadeAnimation;
  final double fadeRadius;
  final bool isEnabled;
  final bool enableGesture;

  const SpoilerConfiguration({
    required this.particleDensity,
    required this.speedOfParticles,
    required this.particleColor,
    required this.maxParticleSize,
    required this.fadeAnimation,
    required this.fadeRadius,
    required this.isEnabled,
    required this.enableGesture,
  });
}