import 'package:flutter/material.dart';
import 'package:inspect/src/widgets/color_picker/utils.dart';

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
        border: Border.all(
          color: Colors.black12,
        ),
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
