import 'package:flutter/material.dart';
import '../utils.dart';
import 'information_box_widget.dart';
import 'overlay_painter.dart';

class BoxInfoWidget extends StatelessWidget {
  const BoxInfoWidget({
    Key? key,
    required this.boxInfo,
  }) : super(key: key);

  final BoxInfo boxInfo;

  Color get _targetColor => Colors.blue.shade700;
  Color get _containerColor => Colors.orange.shade700;

  Widget _buildTargetBoxSizeWidget(BuildContext context) {
    return Positioned(
      top: calculateBoxPosition(
        rect: boxInfo.targetRect,
        height: InformationBoxWidget.preferredHeight,
      ),
      left: boxInfo.targetRect.left,
      child: Align(
        child: InformationBoxWidget.size(
          size: boxInfo.targetRect.size,
          color: _targetColor,
        ),
      ),
    );
  }

  Widget _buildPaddingSizeWidget(
    BuildContext context, {
    required double padding,
    required Rect paddingRect,
  }) {
    return Positioned(
      top: paddingRect.center.dy - InformationBoxWidget.preferredHeight / 2,
      left: paddingRect.center.dx,
      child: Align(
        child: InformationBoxWidget.number(
          number: padding,
          color: _containerColor,
        ),
      ),
    );
  }

  List<Widget> _buildPaddingWidgets(BuildContext context) {
    return [
      if (boxInfo.paddingLeft != null && boxInfo.paddingLeft! > 0)
        _buildPaddingSizeWidget(
          context,
          padding: boxInfo.paddingLeft!,
          paddingRect: boxInfo.paddingRectLeft!,
        ),
      if (boxInfo.paddingTop != null && boxInfo.paddingTop! > 0)
        _buildPaddingSizeWidget(
          context,
          padding: boxInfo.paddingTop!,
          paddingRect: boxInfo.paddingRectTop!,
        ),
      if (boxInfo.paddingRight != null && boxInfo.paddingRight! > 0)
        _buildPaddingSizeWidget(
          context,
          padding: boxInfo.paddingRight!,
          paddingRect: boxInfo.paddingRectRight!,
        ),
      if (boxInfo.paddingBottom != null && boxInfo.paddingBottom! > 0)
        _buildPaddingSizeWidget(
          context,
          padding: boxInfo.paddingBottom!,
          paddingRect: boxInfo.paddingRectBottom!,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          painter: OverlayPainter(
            boxInfo: boxInfo,
            targetRectColor: _targetColor.withOpacity(0.35),
            containerRectColor: _containerColor.withOpacity(0.35),
          ),
        ),
        // ..._buildPaddingWidgets(context),
        _buildTargetBoxSizeWidget(context),
      ],
    );
  }
}
