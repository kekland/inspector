import 'package:flutter/material.dart';

class InspectorPanel extends StatefulWidget {
  const InspectorPanel({
    Key? key,
    required this.isInspectorEnabled,
    required this.isColorPickerEnabled,
    required this.onInspectorStateChanged,
    required this.onColorPickerStateChanged,
    required this.isColorPickerLoading,
  }) : super(key: key);

  final bool isInspectorEnabled;
  final ValueChanged<bool> onInspectorStateChanged;

  final bool isColorPickerEnabled;
  final ValueChanged<bool> onColorPickerStateChanged;

  final bool isColorPickerLoading;

  @override
  _InspectorPanelState createState() => _InspectorPanelState();
}

class _InspectorPanelState extends State<InspectorPanel> {
  bool _isVisible = true;

  void _toggleVisibility() {
    setState(() => _isVisible = !_isVisible);
  }

  void _toggleInspectorState() {
    widget.onInspectorStateChanged(!widget.isInspectorEnabled);
  }

  void _toggleColorPickerState() {
    widget.onColorPickerStateChanged(!widget.isColorPickerEnabled);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            mini: true,
            onPressed: _toggleVisibility,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black54,
            child: Icon(
              _isVisible ? Icons.chevron_right : Icons.chevron_left,
            ),
          ),
          if (_isVisible) ...[
            const SizedBox(height: 16.0),
            FloatingActionButton(
              onPressed: _toggleInspectorState,
              backgroundColor:
                  widget.isInspectorEnabled ? Colors.blue : Colors.white,
              foregroundColor:
                  widget.isInspectorEnabled ? Colors.white : Colors.black54,
              child: const Icon(Icons.format_shapes),
            ),
            const SizedBox(height: 8.0),
            FloatingActionButton(
              onPressed: _toggleColorPickerState,
              backgroundColor:
                  widget.isColorPickerEnabled ? Colors.blue : Colors.white,
              foregroundColor:
                  widget.isColorPickerEnabled ? Colors.white : Colors.black54,
              child: widget.isColorPickerLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.palette),
            ),
          ] else
            const SizedBox(height: 136.0),
        ],
      ),
    );
  }
}
