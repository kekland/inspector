import 'dart:typed_data';

import 'package:flutter/material.dart';

Color getPixelFromByteData(
  ByteData byteData, {
  required int width,
  required int x,
  required int y,
}) {
  final _index = (y * width + x) * 4;

  final r = byteData.getUint8(_index);
  final g = byteData.getUint8(_index + 1);
  final b = byteData.getUint8(_index + 2);
  final a = byteData.getUint8(_index + 3);

  return Color.fromARGB(a, r, g, b);
}

String colorToHexString(Color color) {
  final r = color.red.toRadixString(16).padLeft(2, '0');
  final g = color.green.toRadixString(16).padLeft(2, '0');
  final b = color.blue.toRadixString(16).padLeft(2, '0');

  return '$r$g$b';
}

Color getTextColorOnBackground(Color background) {
  final luminance = background.computeLuminance();

  if (luminance > 0.5) return Colors.black;
  return Colors.white;
}
