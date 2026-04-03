import 'package:flutter/services.dart';

class KeyboardHandler {
  KeyboardHandler({
    required this.onInspectorStateChanged,
    required this.onInspectAndCompareChanged,
    required this.onColorPickerStateChanged,
    required this.onZoomStateChanged,
    this.inspectAndCompareKeys = const [
      LogicalKeyboardKey.keyY,
    ],
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
    this.zoomStateKeys = const [
      LogicalKeyboardKey.keyZ,
    ],
  });

  final void Function(bool) onInspectorStateChanged;
  final void Function(bool) onInspectAndCompareChanged;
  final void Function(bool) onColorPickerStateChanged;
  final void Function(bool) onZoomStateChanged;
  final List<LogicalKeyboardKey> inspectorStateKeys;
  final List<LogicalKeyboardKey> inspectAndCompareKeys;
  final List<LogicalKeyboardKey> colorPickerStateKeys;
  final List<LogicalKeyboardKey> zoomStateKeys;

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

  static final _modifierKeys = {
    LogicalKeyboardKey.alt,
    LogicalKeyboardKey.altLeft,
    LogicalKeyboardKey.altRight,
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.controlRight,
    LogicalKeyboardKey.meta,
    LogicalKeyboardKey.metaLeft,
    LogicalKeyboardKey.metaRight,
  };

  bool _handler(KeyEvent event) {
    if (event is KeyRepeatEvent) return false;

    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final hasModifier = pressed.any(_modifierKeys.contains);

    if (inspectorStateKeys.contains(event.logicalKey)) {
      onInspectorStateChanged(event is! KeyUpEvent);
    } else if (inspectAndCompareKeys.contains(event.logicalKey)) {
      if (event is KeyUpEvent || hasModifier) {
        onInspectAndCompareChanged(event is! KeyUpEvent);
      }
    } else if (colorPickerStateKeys.contains(event.logicalKey)) {
      onColorPickerStateChanged(event is! KeyUpEvent);
    } else if (zoomStateKeys.contains(event.logicalKey)) {
      if (event is KeyUpEvent || hasModifier) {
        onZoomStateChanged(event is! KeyUpEvent);
      }
    }

    return false;
  }
}
