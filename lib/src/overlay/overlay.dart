import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:inspect/src/overlay/information_box_widget.dart';
import 'package:inspect/src/overlay/overlay_painter.dart';
import 'package:inspect/src/overlay/utils.dart';

class InspectorOverlay extends StatefulWidget {
  const InspectorOverlay({
    Key? key,
    required this.size,
    this.renderBox,
    this.outerRenderBox,
  }) : super(key: key);

  final Size size;
  final RenderBox? renderBox;
  final RenderBox? outerRenderBox;

  @override
  _InspectorOverlayState createState() => _InspectorOverlayState();
}

class _InspectorOverlayState extends State<InspectorOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();

    _ticker = this.createTicker((_) => _onTick());
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick() {
    setState(() {});
  }

  Rect? _getRectFromRenderBox(RenderBox? renderBox) {
    return renderBox != null && renderBox.attached
        ? renderBox.localToGlobal(Offset.zero) & renderBox.size
        : null;
  }

  Rect? get _rect => _getRectFromRenderBox(widget.renderBox);
  Rect? get _outerRect => _getRectFromRenderBox(widget.outerRenderBox);

  Color get _boxOverlayColor => Colors.blue.shade700;

  Color get _outerBoxOverlayColor => Colors.red.shade700;

  Widget _buildBoxOverlayInformation(BuildContext context) {
    return Positioned(
      top: calculateBoxPosition(
        rect: _rect!,
        height: InformationBoxWidget.preferredHeight,
      ),
      left: _rect!.left,
      child: Align(
        alignment: Alignment.center,
        child: InformationBoxWidget.size(
          size: _rect!.size,
          color: _boxOverlayColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_rect == null) {
      return SizedBox.shrink();
    }

    return IgnorePointer(
      child: SizedBox(
        width: widget.size.width,
        height: widget.size.height,
        child: Stack(
          children: [
            CustomPaint(
              painter: OverlayPainter(
                targetRect: _rect,
                containerRect: _outerRect,
                targetRectColor: _boxOverlayColor.withOpacity(0.35),
                containerRectColor: _outerBoxOverlayColor.withOpacity(0.35),
              ),
            ),
            _buildBoxOverlayInformation(context),
          ],
        ),
      ),
    );
  }
}
