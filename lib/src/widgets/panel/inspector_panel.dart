import 'package:flutter/material.dart';
import 'package:inspector/src/inspector_controller.dart';

class InspectorPanel extends StatefulWidget {
  const InspectorPanel({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final InspectorController controller;

  @override
  State<InspectorPanel> createState() => _InspectorPanelState();
}

class _InspectorPanelState extends State<InspectorPanel> {
  bool _isVisible = false;

  InspectorController get controller => widget.controller;

  void _toggleVisibility() {
    setState(() => _isVisible = !_isVisible);
  }

  IconData get _visibilityButtonIcon {
    if (_isVisible) return Icons.chevron_right;

    final mode = controller.modeNotifier.value;
    switch (mode) {
      case InspectorMode.inspector:
      case InspectorMode.inspectAndCompare:
        return Icons.format_shapes;
      case InspectorMode.colorPicker:
        return Icons.colorize;
      case InspectorMode.zoom:
        return Icons.zoom_in;
      case InspectorMode.none:
        return Icons.chevron_left;
    }
  }

  Color get _visibilityButtonBackgroundColor {
    if (_isVisible) return Colors.white;

    if (controller.modeNotifier.value != InspectorMode.none) {
      return Colors.blue;
    }

    return Colors.white;
  }

  Color get _visibilityButtonForegroundColor {
    if (_isVisible) return Colors.black54;

    if (controller.modeNotifier.value != InspectorMode.none) {
      return Colors.white;
    }

    return Colors.black54;
  }

  @override
  Widget build(BuildContext context) {
    final mode = controller.modeNotifier.value;

    final _height = 16.0 +
        (controller.isWidgetInspectorEnabled ? 56.0 : 0.0) +
        (controller.isColorPickerEnabled ? 64.0 : 0.0) +
        (controller.isZoomEnabled ? 64.0 : 0.0);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            mini: true,
            onPressed: _toggleVisibility,
            backgroundColor: _visibilityButtonBackgroundColor,
            foregroundColor: _visibilityButtonForegroundColor,
            child: Icon(_visibilityButtonIcon),
          ),
          if (_isVisible) ...[
            const SizedBox(height: 16.0),
            if (controller.isWidgetInspectorEnabled)
              FloatingActionButton(
                onPressed: () => controller.setMode(
                  mode == InspectorMode.inspector
                      ? InspectorMode.none
                      : InspectorMode.inspector,
                ),
                backgroundColor: mode == InspectorMode.inspector
                    ? Colors.blue
                    : Colors.white,
                foregroundColor: mode == InspectorMode.inspector
                    ? Colors.white
                    : Colors.black54,
                child: const Icon(Icons.format_shapes),
              ),
            if (controller.isColorPickerEnabled) ...[
              const SizedBox(height: 8.0),
              FloatingActionButton(
                onPressed: () => controller.setMode(
                  mode == InspectorMode.colorPicker
                      ? InspectorMode.none
                      : InspectorMode.colorPicker,
                  context: context,
                ),
                backgroundColor: mode == InspectorMode.colorPicker
                    ? Colors.blue
                    : Colors.white,
                foregroundColor: mode == InspectorMode.colorPicker
                    ? Colors.white
                    : Colors.black54,
                child: const Icon(Icons.colorize),
              ),
            ],
            if (controller.isZoomEnabled) ...[
              const SizedBox(height: 8.0),
              FloatingActionButton(
                onPressed: () => controller.setMode(
                  mode == InspectorMode.zoom
                      ? InspectorMode.none
                      : InspectorMode.zoom,
                ),
                backgroundColor:
                    mode == InspectorMode.zoom ? Colors.blue : Colors.white,
                foregroundColor:
                    mode == InspectorMode.zoom ? Colors.white : Colors.black54,
                child: const Icon(Icons.zoom_in),
              ),
            ],
          ] else
            SizedBox(height: _height),
        ],
      ),
    );
  }
}
