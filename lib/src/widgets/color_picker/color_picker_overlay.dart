import 'package:flutter/material.dart';

import 'utils.dart';

class ColorPickerOverlay extends StatelessWidget {
  const ColorPickerOverlay({
    Key? key,
    required this.color,
  }) : super(key: key);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56.0,
      height: 56.0,
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
          colorToHexString(color),
          style: TextStyle(
            color: getTextColorOnBackground(color),
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }
}
