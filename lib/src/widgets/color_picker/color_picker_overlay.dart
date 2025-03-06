import 'package:flutter/material.dart';

import 'color_scheme_inspector.dart';
import 'utils.dart';

class ColorPickerOverlay extends StatelessWidget {
  const ColorPickerOverlay({
    Key? key,
    required this.color,
    required this.isColorSchemeHintEnabled,
  }) : super(key: key);

  final Color color;
  final bool isColorSchemeHintEnabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final String? match;

    if (isColorSchemeHintEnabled) {
      match = ColorSchemeInspector.identifyColorSchemeMatch(color, colorScheme);
    } else {
      match = null;
    }

    final colorString = colorToHexString(color);
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
          match != null ? '$colorString $match' : colorString,
          style: TextStyle(
            color: getTextColorOnBackground(color),
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }
}
