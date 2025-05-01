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

import 'package:flutter/material.dart';
import './spoiler_configs.dart';

/// Configuration for the text spoiler widget
/// [style] is the style of the text
/// [selection] is the selection of the text
@immutable
class TextSpoilerConfiguration extends SpoilerConfiguration {
  final TextStyle? style;
  final TextSelection? selection;
  final bool Function()? canAllowGesture;
  const TextSpoilerConfiguration({
    this.style,
    this.selection,
    this.canAllowGesture,
    super.particleDensity = 6,
    super.speedOfParticles = 0.1,
    super.particleColor = const Color(0xFF2563EB),
    super.maxParticleSize = 1,
    super.fadeAnimation = true,
    super.fadeRadius = 1,
    super.isEnabled = true,
    super.enableGesture = false,
  });
}