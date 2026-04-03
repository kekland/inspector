import 'dart:math' as math;

import 'package:flutter/material.dart';

enum CompareSide { left, top, right, bottom }

class CompareDistance {
  const CompareDistance({
    required this.side,
    required this.value,
    required this.icon,
    required this.startOffset,
    required this.endOffset,
    required this.isHorizontal,
  });

  final CompareSide side;

  /// Distance in logical (unzoomed) units.
  final double value;

  /// Directional arrow icon.
  final IconData icon;

  /// Screen coordinates for the start of the measurement line.
  final Offset startOffset;

  /// Screen coordinates for the end of the measurement line.
  final Offset endOffset;

  final bool isHorizontal;
}

/// Computes direction-aware distances between two rects.
///
/// [from] and [to] must be in the same coordinate space (e.g. both shifted
/// by overlayOffset or both in global screen coords).
/// [scale] converts screen pixels to logical units (from InteractiveViewer etc.)
///
/// Three scenarios:
/// - H gap only → one horizontal distance
/// - V gap only → one vertical distance
/// - Both gaps (diagonal) → one H + one V distance
/// - No gap (overlap) → up to 4 LTRB alignment distances
///
/// Distances below 0.5 logical units are omitted.
List<CompareDistance> computeCompareDistances(
  Rect from,
  Rect to, {
  double scale = 1.0,
}) {
  final result = <CompareDistance>[];

  final hasHGap = from.right <= to.left || to.right <= from.left;
  final hasVGap = from.bottom <= to.top || to.bottom <= from.top;

  if (hasHGap) {
    final double lineStart, lineEnd;
    final IconData icon;
    final CompareSide side;

    if (from.right <= to.left) {
      lineStart = from.right;
      lineEnd = to.left;
      icon = Icons.arrow_forward;
      side = CompareSide.right;
    } else {
      lineStart = to.right;
      lineEnd = from.left;
      icon = Icons.arrow_back;
      side = CompareSide.left;
    }

    final value = (lineEnd - lineStart) / scale;
    if (value >= 0.5) {
      final y = (from.center.dy + to.center.dy) / 2;
      result.add(CompareDistance(
        side: side,
        value: value,
        icon: icon,
        startOffset: Offset(lineStart, y),
        endOffset: Offset(lineEnd, y),
        isHorizontal: true,
      ));
    }
  }

  if (hasVGap) {
    final double lineStart, lineEnd;
    final IconData icon;
    final CompareSide side;

    if (from.bottom <= to.top) {
      lineStart = from.bottom;
      lineEnd = to.top;
      icon = Icons.arrow_downward;
      side = CompareSide.bottom;
    } else {
      lineStart = to.bottom;
      lineEnd = from.top;
      icon = Icons.arrow_upward;
      side = CompareSide.top;
    }

    final value = (lineEnd - lineStart) / scale;
    if (value >= 0.5) {
      final x = (from.center.dx + to.center.dx) / 2;
      result.add(CompareDistance(
        side: side,
        value: value,
        icon: icon,
        startOffset: Offset(x, lineStart),
        endOffset: Offset(x, lineEnd),
        isHorizontal: false,
      ));
    }
  }

  if (!hasHGap && !hasVGap) {
    // Overlap — show LTRB alignment differences.
    final midY =
        (math.max(from.top, to.top) + math.min(from.bottom, to.bottom)) / 2;
    final midX =
        (math.max(from.left, to.left) + math.min(from.right, to.right)) / 2;

    final leftDiff = (from.left - to.left).abs() / scale;
    if (leftDiff >= 0.5) {
      final minX = math.min(from.left, to.left);
      final maxX = math.max(from.left, to.left);
      result.add(CompareDistance(
        side: CompareSide.left,
        value: leftDiff,
        icon: from.left < to.left ? Icons.arrow_forward : Icons.arrow_back,
        startOffset: Offset(minX, midY),
        endOffset: Offset(maxX, midY),
        isHorizontal: true,
      ));
    }

    final topDiff = (from.top - to.top).abs() / scale;
    if (topDiff >= 0.5) {
      final minY = math.min(from.top, to.top);
      final maxY = math.max(from.top, to.top);
      result.add(CompareDistance(
        side: CompareSide.top,
        value: topDiff,
        icon: from.top < to.top ? Icons.arrow_downward : Icons.arrow_upward,
        startOffset: Offset(midX, minY),
        endOffset: Offset(midX, maxY),
        isHorizontal: false,
      ));
    }

    final rightDiff = (from.right - to.right).abs() / scale;
    if (rightDiff >= 0.5) {
      final minX = math.min(from.right, to.right);
      final maxX = math.max(from.right, to.right);
      result.add(CompareDistance(
        side: CompareSide.right,
        value: rightDiff,
        icon: from.right > to.right ? Icons.arrow_forward : Icons.arrow_back,
        startOffset: Offset(minX, midY),
        endOffset: Offset(maxX, midY),
        isHorizontal: true,
      ));
    }

    final bottomDiff = (from.bottom - to.bottom).abs() / scale;
    if (bottomDiff >= 0.5) {
      final minY = math.min(from.bottom, to.bottom);
      final maxY = math.max(from.bottom, to.bottom);
      result.add(CompareDistance(
        side: CompareSide.bottom,
        value: bottomDiff,
        icon:
            from.bottom > to.bottom ? Icons.arrow_downward : Icons.arrow_upward,
        startOffset: Offset(midX, minY),
        endOffset: Offset(midX, maxY),
        isHorizontal: false,
      ));
    }
  }

  return result;
}
