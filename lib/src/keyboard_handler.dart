import 'package:flutter/services.dart';

class KeyboardHandler {
  KeyboardHandler({
    required this.onInspectorStateChanged,
    required this.onColorPickerStateChanged,
    this.inspectorStateKeys = const [
      LogicalKeyboardKey.alt,
      LogicalKeyboardKey.altLeft,
      LogicalKeyboardKey.altRight,
    ],
    this.colorPickerStateKeys = const [
      LogicalKeyboardKey.shift,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.shiftRight,
    ],
  });

  final void Function(bool) onInspectorStateChanged;
  final void Function(bool) onColorPickerStateChanged;
  final List<LogicalKeyboardKey> inspectorStateKeys;
  final List<LogicalKeyboardKey> colorPickerStateKeys;

  bool _isRegistered = false;

  void register() {
    if (_isRegistered) return;

    HardwareKeyboard.instance.addHandler(_handler);
    _isRegistered = true;
  }

  void dispose() {
    if (!_isRegistered) return;

    HardwareKeyboard.instance.removeHandler(_handler);
    _isRegistered = false;
  }

  bool _handler(KeyEvent event) {
    if (inspectorStateKeys.contains(event.logicalKey)) {
      onInspectorStateChanged(event is! KeyUpEvent);
    } else if (colorPickerStateKeys.contains(event.logicalKey)) {
      onColorPickerStateChanged(event is! KeyUpEvent);
    }

    return false;
  }
}
