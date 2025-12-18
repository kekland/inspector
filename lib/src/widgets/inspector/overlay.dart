import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../components/box_info_widget.dart';
import 'box_info.dart';

class InspectorOverlay extends StatefulWidget {
  const InspectorOverlay({
    Key? key,
    required this.size,
    required this.boxInfo,
    this.hoveredBoxInfo,
    this.comparedBoxInfo,
  }) : super(key: key);

  final Size size;
  final BoxInfo? boxInfo;
  final BoxInfo? hoveredBoxInfo;
  final BoxInfo? comparedBoxInfo;

  @override
  State<InspectorOverlay> createState() => _InspectorOverlayState();
}

class _InspectorOverlayState extends State<InspectorOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  // Store the last known rect to detect zoom changes
  Rect? _lastBoxInfoTargetRect;
  Rect? _lastHoverBoxInfoTargetRect;
  Rect? _lastComparedBoxInfoTargetRect;

  bool _canRender(BoxInfo? boxInfo) =>
      boxInfo?.targetRenderBox.attached ?? false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;

    // Check if any box can be rendered
    final canRenderBox = _canRender(widget.boxInfo);
    final canRenderHovered = _canRender(widget.hoveredBoxInfo);
    final canRenderCompared = _canRender(widget.comparedBoxInfo);

    if (!canRenderBox && !canRenderHovered && !canRenderCompared) {
      _lastBoxInfoTargetRect = null;
      _lastHoverBoxInfoTargetRect = null;
      _lastComparedBoxInfoTargetRect = null;
      return;
    }

    // Get current rects
    final currentBoxRect =
        canRenderBox ? widget.boxInfo!.targetRectShifted : null;
    final currentHoverRect =
        canRenderHovered ? widget.hoveredBoxInfo!.targetRectShifted : null;
    final currentComparedRect =
        canRenderCompared ? widget.comparedBoxInfo!.targetRectShifted : null;

    // Rebuild if any rect has changed (Need for zoom/pan occurred)
    if (currentBoxRect != _lastBoxInfoTargetRect ||
        currentHoverRect != _lastHoverBoxInfoTargetRect ||
        currentComparedRect != _lastComparedBoxInfoTargetRect) {
      _lastBoxInfoTargetRect = currentBoxRect;
      _lastHoverBoxInfoTargetRect = currentHoverRect;
      _lastComparedBoxInfoTargetRect = currentComparedRect;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_canRender(widget.boxInfo) && !_canRender(widget.hoveredBoxInfo)) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: widget.size.width,
      height: widget.size.height,
      child: BoxInfoWidget(
        boxInfo: widget.boxInfo,
        hoveredBoxInfo: widget.hoveredBoxInfo,
        comparedBoxInfo: widget.comparedBoxInfo,
      ),
    );
  }
}
