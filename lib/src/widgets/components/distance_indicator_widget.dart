import 'package:flutter/material.dart';

import '../inspector/box_info.dart';

/// A widget that displays distance indicators between two boxes,
/// similar to Figma's measurement tool.
class DistanceIndicatorWidget extends StatelessWidget {
  const DistanceIndicatorWidget({
    required this.boxInfo,
    required this.comparedBoxInfo,
    required this.color,
    Key? key,
  }) : super(key: key);

  final BoxInfo boxInfo;
  final BoxInfo comparedBoxInfo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final boxRect = boxInfo.targetRectShifted;
    final comparedRect = comparedBoxInfo.targetRectShifted;

    final bool comparedInsideBox =
        boxInfo.targetRenderBox.size > comparedBoxInfo.targetRenderBox.size;
    final bool boxInsideCompared =
        comparedBoxInfo.targetRenderBox.size > boxInfo.targetRenderBox.size;

    return Stack(
      children: [
        _buildLeftDistance(
            boxRect, comparedRect, comparedInsideBox, boxInsideCompared),
        _buildRightDistance(
            boxRect, comparedRect, comparedInsideBox, boxInsideCompared),
        _buildTopDistance(
            boxRect, comparedRect, comparedInsideBox, boxInsideCompared),
        _buildBottomDistance(
            boxRect, comparedRect, comparedInsideBox, boxInsideCompared),
      ],
    );
  }

  Widget _buildLeftDistance(
    Rect boxRect,
    Rect comparedRect,
    bool comparedInsideBox,
    bool boxInsideCompared,
  ) {
    double distance;
    Offset start;
    Offset end;

    if (comparedInsideBox) {
      distance = comparedRect.left - boxRect.left;
      start = Offset(boxRect.left, comparedRect.center.dy);
      end = Offset(comparedRect.left, comparedRect.center.dy);
    } else if (boxInsideCompared) {
      distance = boxRect.left - comparedRect.left;
      start = Offset(comparedRect.left, boxRect.center.dy);
      end = Offset(boxRect.left, boxRect.center.dy);
    } else {
      distance = boxRect.left - comparedRect.right;
      start = Offset(boxRect.left, boxRect.center.dy);
      end = Offset(comparedRect.right, boxRect.center.dy);

      if (distance <= 0) {
        distance = boxRect.left - comparedRect.left;
        if (distance <= 0) return const SizedBox.shrink();
        end = Offset(comparedRect.left, boxRect.center.dy);
      }
    }

    if (distance <= 0) return const SizedBox.shrink();

    return CustomPaint(
      painter: _DistanceLinePainter(
        start: start,
        end: end,
        distance: distance,
        color: color,
        direction: Axis.horizontal,
      ),
    );
  }

  Widget _buildRightDistance(
    Rect boxRect,
    Rect comparedRect,
    bool comparedInsideBox,
    bool boxInsideCompared,
  ) {
    double distance;
    Offset start;
    Offset end;

    if (comparedInsideBox) {
      distance = boxRect.right - comparedRect.right;
      start = Offset(comparedRect.right, comparedRect.center.dy);
      end = Offset(boxRect.right, comparedRect.center.dy);
    } else if (boxInsideCompared) {
      distance = comparedRect.right - boxRect.right;
      start = Offset(boxRect.right, boxRect.center.dy);
      end = Offset(comparedRect.right, boxRect.center.dy);
    } else {
      distance = comparedRect.left - boxRect.right;
      start = Offset(boxRect.right, boxRect.center.dy);
      end = Offset(comparedRect.left, boxRect.center.dy);

      if (distance <= 0) {
        distance = comparedRect.right - boxRect.right;
        if (distance <= 0) return const SizedBox.shrink();
        end = Offset(comparedRect.right, boxRect.center.dy);
      }
    }

    if (distance <= 0) return const SizedBox.shrink();

    return CustomPaint(
      painter: _DistanceLinePainter(
        start: start,
        end: end,
        distance: distance,
        color: color,
        direction: Axis.horizontal,
      ),
    );
  }

  Widget _buildTopDistance(
    Rect boxRect,
    Rect comparedRect,
    bool comparedInsideBox,
    bool boxInsideCompared,
  ) {
    double distance;
    Offset start;
    Offset end;

    if (comparedInsideBox) {
      distance = comparedRect.top - boxRect.top;
      start = Offset(comparedRect.center.dx, boxRect.top);
      end = Offset(comparedRect.center.dx, comparedRect.top);
    } else if (boxInsideCompared) {
      distance = boxRect.top - comparedRect.top;
      start = Offset(boxRect.center.dx, comparedRect.top);
      end = Offset(boxRect.center.dx, boxRect.top);
    } else {
      distance = boxRect.top - comparedRect.bottom;
      start = Offset(boxRect.center.dx, boxRect.top);
      end = Offset(boxRect.center.dx, comparedRect.bottom);

      if (distance <= 0) {
        distance = boxRect.top - comparedRect.top;
        if (distance <= 0) return const SizedBox.shrink();
        end = Offset(boxRect.center.dx, comparedRect.top);
      }
    }

    if (distance <= 0) return const SizedBox.shrink();

    return CustomPaint(
      painter: _DistanceLinePainter(
        start: start,
        end: end,
        distance: distance,
        color: color,
        direction: Axis.vertical,
      ),
    );
  }

  Widget _buildBottomDistance(
    Rect boxRect,
    Rect comparedRect,
    bool comparedInsideBox,
    bool boxInsideCompared,
  ) {
    double distance;
    Offset start;
    Offset end;

    if (comparedInsideBox) {
      distance = boxRect.bottom - comparedRect.bottom;
      start = Offset(comparedRect.center.dx, comparedRect.bottom);
      end = Offset(comparedRect.center.dx, boxRect.bottom);
    } else if (boxInsideCompared) {
      distance = comparedRect.bottom - boxRect.bottom;
      start = Offset(boxRect.center.dx, boxRect.bottom);
      end = Offset(boxRect.center.dx, comparedRect.bottom);
    } else {
      distance = comparedRect.top - boxRect.bottom;
      start = Offset(boxRect.center.dx, boxRect.bottom);
      end = Offset(boxRect.center.dx, comparedRect.top);

      if (distance <= 0) {
        distance = comparedRect.bottom - boxRect.bottom;
        if (distance <= 0) return const SizedBox.shrink();
        end = Offset(boxRect.center.dx, comparedRect.bottom);
      }
    }

    if (distance <= 0) return const SizedBox.shrink();

    return CustomPaint(
      painter: _DistanceLinePainter(
        start: start,
        end: end,
        distance: distance,
        color: color,
        direction: Axis.vertical,
      ),
    );
  }
}

class _DistanceLinePainter extends CustomPainter {
  _DistanceLinePainter({
    required this.start,
    required this.end,
    required this.distance,
    required this.color,
    required this.direction,
  });

  final Offset start;
  final Offset end;
  final double distance;
  final Color color;
  final Axis direction;

  static const double labelPadding = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, end, paint);

    _drawLabel(canvas);
  }

  void _drawLabel(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: distance.toStringAsFixed(1),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final labelWidth = textPainter.width + labelPadding * 2;
    final labelHeight = textPainter.height + labelPadding * 2;
    const double labelOffset = 6.0;

    final Offset lineCenter = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );

    final Offset labelCenter;
    if (direction == Axis.horizontal) {
      labelCenter = Offset(
        lineCenter.dx,
        lineCenter.dy - labelHeight / 2 - labelOffset,
      );
    } else {
      labelCenter = Offset(
        lineCenter.dx + labelWidth / 2 + labelOffset,
        lineCenter.dy,
      );
    }

    final Rect labelRect = Rect.fromCenter(
      center: labelCenter,
      width: labelWidth,
      height: labelHeight,
    );

    final labelPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(3)),
      labelPaint,
    );

    textPainter.paint(
      canvas,
      Offset(
        labelRect.left + labelPadding,
        labelRect.top + labelPadding,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _DistanceLinePainter oldDelegate) =>
      start != oldDelegate.start ||
      end != oldDelegate.end ||
      distance != (oldDelegate).distance ||
      color != oldDelegate.color ||
      direction != oldDelegate.direction;
}
