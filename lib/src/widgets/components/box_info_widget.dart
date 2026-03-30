import 'package:flutter/material.dart';
import 'package:inspector/src/widgets/inspector/render_box_extension.dart';

import '../inspector/box_info.dart';
import 'box_info_panel_widget.dart';
import 'information_box_widget.dart';
import 'overlay_painter.dart';

class BoxInfoWidget extends StatelessWidget {
  const BoxInfoWidget({
    Key? key,
    this.boxInfo,
    this.hoveredBoxInfo,
    this.comparedBoxInfo,
  }) : super(key: key);

  final BoxInfo? boxInfo;
  final BoxInfo? hoveredBoxInfo;
  final BoxInfo? comparedBoxInfo;

  Color get _targetColor => Colors.blue.shade700;

  Color get _containerColor => Colors.yellow.shade700;

  Widget _buildTargetBoxSizeWidget(BuildContext context) {
    return Positioned(
      top: calculateBoxPosition(
        rect: boxInfo!.targetRectShifted,
        height: InformationBoxWidget.preferredHeight,
      ),
      left: boxInfo!.targetRectShifted.left,
      child: IgnorePointer(
        child: Align(
          child: InformationBoxWidget.size(
            size: boxInfo!.targetRenderBox.displaySize,
            color: _targetColor,
          ),
        ),
      ),
    );
  }

  Widget _buildTargetBoxInfoPanel(BuildContext context) {
    return BoxInfoPanelWidget(
      boxInfo: boxInfo!,
      comparedBoxInfo: comparedBoxInfo,
    );
  }

  Widget _buildBoxOverlay(
    BuildContext context,
    BoxInfo boxInfo, {
    bool showContainerRenderBox = true,
  }) {
    return IgnorePointer(
      child: CustomPaint(
        painter: OverlayPainter(
          boxInfo: boxInfo,
          targetRectColor: _targetColor.withValues(alpha: 0.35),
          containerRectColor: _containerColor.withValues(alpha: 0.35),
          showContainerRenderBox: showContainerRenderBox,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (boxInfo?.targetRenderBox.attached == true)
          _buildBoxOverlay(context, boxInfo!),
        if (hoveredBoxInfo?.targetRenderBox.attached == true)
          _buildBoxOverlay(context, hoveredBoxInfo!,
              showContainerRenderBox: false),
        if (comparedBoxInfo?.targetRenderBox.attached == true)
          _buildBoxOverlay(context, comparedBoxInfo!,
              showContainerRenderBox: false),
        // ..._buildPaddingWidgets(context),
        if (boxInfo?.targetRenderBox.attached == true) ...[
          _buildTargetBoxSizeWidget(context),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: _buildTargetBoxInfoPanel(context),
            ),
          ),
        ],
      ],
    );
  }
}
