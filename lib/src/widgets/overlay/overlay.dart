import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import './components/box_info_widget.dart';
import 'utils.dart';

class InspectorOverlay extends StatefulWidget {
  const InspectorOverlay({
    Key? key,
    required this.size,
    this.targetRenderBox,
    this.containerRenderBox,
  }) : super(key: key);

  final Size size;
  final RenderBox? targetRenderBox;
  final RenderBox? containerRenderBox;

  @override
  _InspectorOverlayState createState() => _InspectorOverlayState();
}

class _InspectorOverlayState extends State<InspectorOverlay> {
  @override
  void initState() {
    super.initState();
    _onTick(null);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onTick(Duration? tick) {
    if (!mounted) return;

    setState(() {});

    WidgetsBinding.instance?.scheduleFrameCallback(
      _onTick,
      rescheduling: tick != null,
    );
  }

  bool get _canRender =>
      widget.targetRenderBox != null && widget.targetRenderBox!.attached;

  BoxInfo? get _boxInfo => _canRender
      ? BoxInfo.fromRenderBoxes(
          targetRenderBox: widget.targetRenderBox!,
          containerRenderBox: widget.containerRenderBox,
        )
      : null;

  @override
  Widget build(BuildContext context) {
    if (!_canRender) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: SizedBox(
        width: widget.size.width,
        height: widget.size.height,
        child: BoxInfoWidget(
          boxInfo: _boxInfo!,
        ),
      ),
    );
  }
}
