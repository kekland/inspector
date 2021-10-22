import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:inspect/src/widgets/inspector/box_info.dart';

class BoxModelPainter extends CustomPainter {
  BoxModelPainter({
    required this.boxInfo,
    required this.targetColor,
    required this.containerColor,
  });

  final BoxInfo boxInfo;
  final Color targetColor;
  final Color containerColor;

  Paint get _targetPaint => Paint()
    ..color = targetColor
    ..style = PaintingStyle.fill;

  Paint get _containerPaint => Paint()..color = containerColor;

  Paint get _containerDashPaint =>
      Paint()..color = containerColor.withOpacity(0.35);

  final double _dashWidth = 4.0;
  final double _dashSkip = 0.0;

  void _paintBackground(Canvas canvas, Size size) {
    final _sizePath = Path();
    _sizePath.moveTo(0.0, 0.0);
    _sizePath.lineTo(size.width, 0.0);
    _sizePath.lineTo(size.width, size.height);
    _sizePath.lineTo(0.0, size.height);

    double _dashPosition = 0.0;
    while (_dashPosition < size.height * 2) {
      final _path = Path();

      _path.moveTo(0.0, _dashPosition);
      _path.lineTo(_dashPosition, 0.0);
      _path.lineTo(_dashPosition + _dashWidth, 0.0);
      _path.lineTo(0.0, _dashPosition + _dashWidth);

      canvas.drawPath(
        Path.combine(PathOperation.intersect, _path, _sizePath),
        _containerDashPaint,
      );

      _dashPosition += _dashWidth + _dashSkip;
    }
  }

  void _paintForeground(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(
        size.width / 4.0,
        size.height / 4.0,
        size.width / 2.0,
        size.height / 2.0,
      ),
      _targetPaint,
    );
  }

  TextPainter _getTextPainter(String text) {
    const _textStyle = TextStyle(fontSize: 8.0);

    final _span = TextSpan(text: text, style: _textStyle);
    return TextPainter(text: _span, textDirection: TextDirection.ltr);
  }

  void _paintBoxSize(Canvas canvas, Size size) {
    final _painter = _getTextPainter('144 x 50');
    _painter.layout(maxWidth: size.width / 2.0);

    _painter.paint(
      canvas,
      Offset(size.width - _painter.width, size.height - _painter.height) / 2.0,
    );
  }

  void _paintPaddingBox(
    Canvas canvas,
    Size size, {
    required double padding,
    required Offset offset,
  }) {
    final _painter = _getTextPainter(padding.toStringAsFixed(1));
    _painter.layout(maxWidth: size.width / 4.0);

    final _topLeft = Offset(
      offset.dx - _painter.width / 2.0,
      offset.dy - _painter.height / 2.0,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        _topLeft & _painter.size,
        const Radius.circular(2.0),
      ),
      _containerPaint,
    );

    _painter.paint(canvas, _topLeft);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    _paintForeground(canvas, size);
    _paintBoxSize(canvas, size);

    _paintPaddingBox(
      canvas,
      size,
      padding: boxInfo.paddingLeft!,
      offset: Offset(
        size.width / 8.0,
        size.height / 2.0,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
