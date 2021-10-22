import 'package:flutter/material.dart';
import '../inspector/utils.dart';
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
