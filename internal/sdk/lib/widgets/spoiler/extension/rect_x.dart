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

import 'package:flutter/rendering.dart';

extension RectX on Rect {
  /// Check if {offset} is inside the rectangle
  ///
  /// Example:
  /// ```dart
  /// final rect = Rect.fromLTWH(0, 0, 100, 100);
  /// final offset = Offset(50, 50);
  ///
  /// rect.containsOffset(offset); // true
  /// ```
  ///
  bool containsOffset(Offset offset) {
    return bottom >= offset.dy &&
        top <= offset.dy &&
        left <= offset.dx &&
        right >= offset.dx;
  }

  (Rect, Rect, Rect, Rect) divideRect() {
    final halfWidth = width / 2;
    final halfHeight = height / 2;

    final topLeft =
        Rect.fromLTRB(left, top, left + halfWidth, top + halfHeight);
    final topRight =
        Rect.fromLTRB(left + halfWidth, top, right, top + halfHeight);
    final bottomLeft =
        Rect.fromLTRB(left, top + halfHeight, left + halfWidth, bottom);
    final bottomRight =
        Rect.fromLTRB(left + halfWidth, top + halfHeight, right, bottom);

    return (topLeft, topRight, bottomLeft, bottomRight);
  }

  /// Get the farthest corner from {offset}
  Offset getFarthestPoint(Offset offset) {
    final (topLeft, topRight, bottomLeft, bottomRight) = divideRect();

    if (topLeft.containsOffset(offset)) {
      return bottomRight.bottomRight;
    } else if (topRight.containsOffset(offset)) {
      return bottomLeft.bottomLeft;
    } else if (bottomLeft.containsOffset(offset)) {
      return topRight.topRight;
    } else if (bottomRight.containsOffset(offset)) {
      return topLeft.topLeft;
    } else {
      return center;
    }
  }

  /// Get the nearest corner from {offset}
  Offset getNearestPoint(Offset offset) {
    // Clamp the x-coordinate of the offset within the rect's horizontal boundaries
    final nearestX = offset.dx.clamp(left, right);

    // Clamp the y-coordinate of the offset within the rect's vertical boundaries
    final nearestY = offset.dy.clamp(top, bottom);

    // Return the nearest corner
    return Offset(nearestX, nearestY);
  }

  /// Get random offset inside the rectangle
  Offset randomOffset() {
    final maxX = (width + left);
    final minX = left;
    final maxY = (height + top);
    final minY = top;

    return Offset(
      minX + (Random().nextDouble() * (maxX - minX)),
      minY + (Random().nextDouble() * (maxY - minY)),
    );
  }
}

extension ListRectX on List<Rect> {
  Rect getBounds() {
    if (isEmpty) {
      return Rect.zero;
    }

    var left = first.left;
    var top = first.top;
    var right = first.right;
    var bottom = first.bottom;

    for (final rect in this) {
      if (rect.left < left) {
        left = rect.left;
      }

      if (rect.top < top) {
        top = rect.top;
      }

      if (rect.right > right) {
        right = rect.right;
      }

      if (rect.bottom > bottom) {
        bottom = rect.bottom;
      }
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }
}