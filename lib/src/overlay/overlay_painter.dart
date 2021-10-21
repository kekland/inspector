import 'package:flutter/widgets.dart';

class OverlayPainter extends CustomPainter {
  OverlayPainter({
    this.targetRect,
    this.containerRect,
    required this.targetRectColor,
    required this.containerRectColor,
  });

  final Rect? targetRect;
  final Rect? containerRect;

  final Color targetRectColor;
  final Color containerRectColor;

  Paint get targetRectPaint => Paint()..color = targetRectColor;
  Paint get containerRectPaint => Paint()..color = containerRectColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (targetRect != null) {
      canvas.drawRect(targetRect!, targetRectPaint);

      if (containerRect != null) {
        final leftRect = Rect.fromLTRB(
          containerRect!.left,
          containerRect!.top,
          targetRect!.left,
          containerRect!.bottom,
        );

        final topRect = Rect.fromLTRB(
          targetRect!.left,
          containerRect!.top,
          targetRect!.right,
          targetRect!.top,
        );

        final rightRect = Rect.fromLTRB(
          targetRect!.right,
          containerRect!.top,
          containerRect!.right,
          containerRect!.bottom,
        );

        final bottomRect = Rect.fromLTRB(
          targetRect!.left,
          targetRect!.bottom,
          targetRect!.right,
          containerRect!.bottom,
        );

        final rects = [leftRect, topRect, rightRect, bottomRect];
        rects.forEach((r) => canvas.drawRect(r, containerRectPaint));
      }
    }
  }

  @override
  bool shouldRepaint(OverlayPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.containerRect != containerRect;
  }
}
