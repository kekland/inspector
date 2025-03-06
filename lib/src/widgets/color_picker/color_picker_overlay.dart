import 'package:flutter/material.dart';

import 'color_scheme_inspector.dart';
import 'utils.dart';

class ColorPickerOverlay extends StatelessWidget {
  const ColorPickerOverlay({
    Key? key,
    required this.color,
  }) : super(key: key);

  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final match =
        ColorSchemeInspector.identifyColorSchemeMatch(color, colorScheme);
    return Container(
      width: 102.0,
      height: 102.0,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4.0),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12.0,
            color: Colors.black12,
            offset: Offset(0.0, 8.0),
          ),
        ],
      ),
      alignment: Alignment.bottomRight,
      child: Material(
        type: MaterialType.transparency,
        child: Text(
          '${colorToHexString(color)} $match',
          style: TextStyle(
            color: getTextColorOnBackground(color),
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }
}
