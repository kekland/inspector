import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Returns the color of a pixel at the given [x], [y] coordinates.
///
Color? getPixelFromByteData(
  ByteData byteData, {
  required int width,
  required int height,
  required int x,
  required int y,
}) {
  // Bounds check to prevent RangeError
  if (x < 0 || x >= width || y < 0 || y >= height) {
    return null;
  }

  final index = (y * width + x) * 4;

  if (index < 0 || index + 3 >= byteData.lengthInBytes) {
    return null;
  }

  final r = byteData.getUint8(index);
  final g = byteData.getUint8(index + 1);
  final b = byteData.getUint8(index + 2);
  final a = byteData.getUint8(index + 3);

  return Color.fromARGB(a, r, g, b);
}

/// Returns the [color] in hexadecimal (#RRGGBB) format.
///
/// If [withAlpha] is [true], then returns it in #AARRGGBB format.
String colorToHexString(Color color, {bool withAlpha = false}) {
  final a = (color.a * 255).round().toRadixString(16).padLeft(2, '0');
  final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
  final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
  final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');

  if (withAlpha) {
    return '$a$r$g$b';
  }

  return '$r$g$b';
}

Color getTextColorOnBackground(Color background) {
  final luminance = background.computeLuminance();

  if (luminance > 0.5) return Colors.black;
  return Colors.white;
}
