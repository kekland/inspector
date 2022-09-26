import 'package:flutter/material.dart';
import '../components/box_info_widget.dart';
import 'box_info.dart';

class InspectorOverlay extends StatefulWidget {
  const InspectorOverlay({
    Key? key,
    required this.size,
    required this.boxInfo,
  }) : super(key: key);

  final Size size;
  final BoxInfo? boxInfo;

  @override
  _InspectorOverlayState createState() => _InspectorOverlayState();
}

class _InspectorOverlayState extends State<InspectorOverlay> {
  final _panelVisibilityNotifier = ValueNotifier<bool>(false);

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

    WidgetsBinding.instance.scheduleFrameCallback(
      _onTick,
      rescheduling: tick != null,
    );
  }

  bool get _canRender => widget.boxInfo?.targetRenderBox.attached ?? false;

  @override
  Widget build(BuildContext context) {
    if (!_canRender) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: widget.size.width,
      height: widget.size.height,
      child: ValueListenableBuilder(
        valueListenable: _panelVisibilityNotifier,
        builder: (context, bool isVisible, _) => BoxInfoWidget(
          boxInfo: widget.boxInfo!,
          isPanelVisible: isVisible,
          onPanelVisibilityChanged: (v) => _panelVisibilityNotifier.value = v,
        ),
      ),
    );
  }
}
