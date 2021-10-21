import 'package:flutter/material.dart';

class InformationBoxWidget extends StatelessWidget {
  const InformationBoxWidget({
    Key? key,
    required this.child,
    this.color,
  }) : super(key: key);

  factory InformationBoxWidget.size({
    Key? key,
    required Size size,
    Color? color,
  }) {
    return InformationBoxWidget(
      key: key,
      color: color,
      child: Text(
        '${size.width.toStringAsFixed(1)} × ${size.height.toStringAsFixed(1)}',
      ),
    );
  }

  factory InformationBoxWidget.number({
    Key? key,
    required double number,
    Color? color,
  }) {
    return InformationBoxWidget(
      key: key,
      color: color,
      child: Text(number.toStringAsFixed(1)),
    );
  }

  final Widget child;
  final Color? color;

  static double get preferredHeight => 24.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredHeight,
      decoration: BoxDecoration(
        color: color ?? Colors.blue,
        borderRadius: BorderRadius.circular(4.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontSize: 14.0,
          color: Colors.white,
        ),
        maxLines: 1,
        overflow: TextOverflow.visible,
        child: child,
      ),
    );
  }
}
