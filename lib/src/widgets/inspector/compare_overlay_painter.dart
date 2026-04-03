import 'package:flutter/material.dart';

import 'box_info.dart';
import 'compare_distances.dart';

class CompareOverlayPainter extends CustomPainter {
  const CompareOverlayPainter({
    required this.boxInfoA,
    required this.boxInfoB,
    required this.lineColor,
  });

  final BoxInfo boxInfoA;
  final BoxInfo boxInfoB;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (!boxInfoA.targetRenderBox.attached ||
        !boxInfoB.targetRenderBox.attached) {
      return;
    }

    final from = boxInfoA.targetRectShifted;
    final to = boxInfoB.targetRectShifted;

    final originalWidth = boxInfoA.targetRenderBox.size.width;
    final scale = originalWidth > 0 ? from.width / originalWidth : 1.0;

    final distances = computeCompareDistances(from, to, scale: scale);
    if (distances.isEmpty) return;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final d in distances) {
      _drawMeasurement(
        canvas,
        d.startOffset,
        d.endOffset,
        isHorizontal: d.isHorizontal,
        paint: linePaint,
      );
    }
  }

  void _drawMeasurement(
    Canvas canvas,
    Offset start,
    Offset end, {
    required bool isHorizontal,
    required Paint paint,
  }) {
    _drawDashedLine(canvas, start, end, paint);
    _drawCaps(canvas, start, end, isHorizontal, paint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 4.0;
    const gapLength = 3.0;

    final total = (end - start).distance;
    if (total < 0.5) return;

    final direction = (end - start) / total;
    var current = 0.0;
    var drawing = true;

    while (current < total) {
      final segmentLength = drawing ? dashLength : gapLength;
      final next = (current + segmentLength).clamp(0.0, total);

      if (drawing) {
        canvas.drawLine(
          start + direction * current,
          start + direction * next,
          paint,
        );
      }

      current = next;
      drawing = !drawing;
    }
  }

  void _drawCaps(
    Canvas canvas,
    Offset start,
    Offset end,
    bool isHorizontal,
    Paint paint,
  ) {
    const cap = 4.0;
    if (isHorizontal) {
      canvas.drawLine(
        Offset(start.dx, start.dy - cap),
        Offset(start.dx, start.dy + cap),
        paint,
      );
      canvas.drawLine(
        Offset(end.dx, end.dy - cap),
        Offset(end.dx, end.dy + cap),
        paint,
      );
    } else {
      canvas.drawLine(
        Offset(start.dx - cap, start.dy),
        Offset(start.dx + cap, start.dy),
        paint,
      );
      canvas.drawLine(
        Offset(end.dx - cap, end.dy),
        Offset(end.dx + cap, end.dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CompareOverlayPainter oldDelegate) =>
      oldDelegate.boxInfoA != boxInfoA ||
      oldDelegate.boxInfoB != boxInfoB ||
      oldDelegate.lineColor != lineColor;
}
