import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:inspector/src/keyboard_handler.dart';

import './widgets/panel/inspector_panel.dart';
import 'utils.dart';
import 'widgets/color_picker/color_picker_overlay.dart';
import 'widgets/color_picker/color_picker_snackbar.dart';
import 'widgets/color_picker/utils.dart';
import 'widgets/inspector/box_info.dart';
import 'widgets/inspector/overlay.dart';
import 'widgets/multi_value_listenable.dart';

/// [Inspector] can wrap any [child], and will display its control panel and
/// information overlay on top of that [child].
///
/// You should use [Inspector] as a wrapper to [WidgetsApp.builder] or
/// [MaterialApp.builder].
///
/// If [isEnabled] is [null], then [Inspector] is automatically disabled on
/// production builds (i.e. [kReleaseMode] is [true]).
///
/// You can disable the widget inspector or the color picker by passing [false]
/// to either [isWidgetInspectorEnabled] or [isColorPickerEnabled].
///
/// There are also keyboard shortcuts for the widget inspector and the color
/// picker. By default, pressing **Shift** will enable the color picker, and
/// pressing **Command** or **Alt** will enable the widget inspector. Those
/// shortcuts can be changed through [widgetInspectorShortcuts] and
/// [colorPickerShortcuts].
///
/// [isPanelVisible] controls the visibility of the control panel - setting it
/// to [false] will hide the panel, but the other functionality can still be
/// accessed through keyboard shortcuts. If you want to disable the inspector
/// entirely, use [isEnabled].
class Inspector extends StatefulWidget {
  const Inspector({
    Key? key,
    required this.child,
    this.alignment = Alignment.center,
    this.areKeyboardShortcutsEnabled = true,
    this.isPanelVisible = true,
    this.isWidgetInspectorEnabled = true,
    this.isColorPickerEnabled = true,
    this.widgetInspectorShortcuts = const [
      LogicalKeyboardKey.alt,
      LogicalKeyboardKey.altLeft,
      LogicalKeyboardKey.altRight,
      LogicalKeyboardKey.meta,
      LogicalKeyboardKey.metaLeft,
      LogicalKeyboardKey.metaRight,
    ],
    this.colorPickerShortcuts = const [
      LogicalKeyboardKey.shift,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.shiftRight,
    ],
    this.isEnabled,
  }) : super(key: key);

  final Widget child;
  final bool areKeyboardShortcutsEnabled;
  final bool isPanelVisible;
  final bool isWidgetInspectorEnabled;
  final bool isColorPickerEnabled;
  final Alignment alignment;
  final List<LogicalKeyboardKey> widgetInspectorShortcuts;
  final List<LogicalKeyboardKey> colorPickerShortcuts;
  final bool? isEnabled;

  @override
  _InspectorState createState() => _InspectorState();
}

class _InspectorState extends State<Inspector> {
  final _stackKey = GlobalKey();
  final _repaintBoundaryKey = GlobalKey();
  final _absorbPointerKey = GlobalKey();
  ui.Image? _image;

  final _byteDataStateNotifier = ValueNotifier<ByteData?>(null);

  final _currentRenderBoxNotifier = ValueNotifier<BoxInfo?>(null);

  final _inspectorStateNotifier = ValueNotifier<bool>(false);
  final _colorPickerStateNotifier = ValueNotifier<bool>(false);

  final _selectedColorOffsetNotifier = ValueNotifier<Offset?>(null);
  final _selectedColorStateNotifier = ValueNotifier<Color?>(null);

  late final KeyboardHandler _keyboardHandler;

  @override
  void initState() {
    super.initState();

    _keyboardHandler = KeyboardHandler(
      onInspectorStateChanged: _onInspectorStateChanged,
      onColorPickerStateChanged: _onColorPickerStateChanged,
      colorPickerStateKeys: widget.colorPickerShortcuts,
      inspectorStateKeys: widget.widgetInspectorShortcuts,
    );

    if (_isEnabled && widget.areKeyboardShortcutsEnabled) {
      _keyboardHandler.register();
    }
  }

  // Gestures

  void _onTap(Offset? pointerOffset) {
    if (_colorPickerStateNotifier.value) {
      if (pointerOffset != null) {
        _onHover(pointerOffset);
      }

      _onColorPickerStateChanged(false);
    }

    if (!_inspectorStateNotifier.value) {
      return;
    }

    if (pointerOffset == null) return;

    final boxes = InspectorUtils.onTap(
      _absorbPointerKey.currentContext!,
      pointerOffset,
    );

    if (boxes.isEmpty) return;

    final overlayOffset =
        (_stackKey.currentContext!.findRenderObject() as RenderStack)
            .localToGlobal(Offset.zero);

    _currentRenderBoxNotifier.value = BoxInfo.fromHitTestResults(
      boxes,
      overlayOffset: overlayOffset,
    );
  }

  void _onPointerMove(Offset pointerOffset) {
    if (_colorPickerStateNotifier.value) {
      _onHover(pointerOffset);
    }
  }

  // Inspector

  void _onInspectorStateChanged(bool isEnabled) {
    if (!widget.isWidgetInspectorEnabled) {
      _inspectorStateNotifier.value = false;
      return;
    }

    _inspectorStateNotifier.value = isEnabled;

    if (isEnabled) {
      _onColorPickerStateChanged(false);
    } else {
      _currentRenderBoxNotifier.value = null;
    }
  }

  // Color picker

  void _onColorPickerStateChanged(bool isEnabled) {
    if (!widget.isColorPickerEnabled) {
      _colorPickerStateNotifier.value = false;
      return;
    }

    _colorPickerStateNotifier.value = isEnabled;

    if (isEnabled) {
      _onInspectorStateChanged(false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _extractByteData();
      });
    } else {
      if (_selectedColorStateNotifier.value != null) {
        showColorPickerResultSnackbar(
          context: context,
          color: _selectedColorStateNotifier.value!,
        );
      }

      _image?.dispose();
      _image = null;
      _byteDataStateNotifier.value = null;

      _selectedColorOffsetNotifier.value = null;
      _selectedColorStateNotifier.value = null;
    }
  }

  Future<void> _extractByteData() async {
    final boundary = _repaintBoundaryKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;

    _image = await boundary.toImage();
    _byteDataStateNotifier.value = await _image!.toByteData();
  }

  void _onHover(Offset offset) {
    if (_image == null || _byteDataStateNotifier.value == null) return;

    final _x = offset.dx.round();
    final _y = offset.dy.round();

    _selectedColorStateNotifier.value = getPixelFromByteData(
      _byteDataStateNotifier.value!,
      width: _image!.width,
      x: _x,
      y: _y,
    );

    _selectedColorOffsetNotifier.value = offset;
  }

  @override
  void didUpdateWidget(covariant Inspector oldWidget) {
    if (oldWidget.isEnabled != widget.isEnabled) {
      if (_isEnabled && widget.areKeyboardShortcutsEnabled) {
        _keyboardHandler.register();
      } else {
        _keyboardHandler.dispose();
      }
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _image?.dispose();
    _byteDataStateNotifier.value = null;
    _keyboardHandler.dispose();
    super.dispose();
  }

  /// The inspector is enabled if:
  /// 1. [widget.isEnabled] is [null] and we're running in debug mode, or
  /// 2. [widget.isEnabled] is [true]
  bool get _isEnabled =>
      (widget.isEnabled == null && !kReleaseMode) ||
      (widget.isEnabled != null && widget.isEnabled!);

  @override
  Widget build(BuildContext context) {
    if (!_isEnabled) {
      return widget.child;
    }

    return Stack(
      key: _stackKey,
      children: [
        Align(
          alignment: widget.alignment,
          child: MultiValueListenableBuilder(
            valueListenables: [
              _colorPickerStateNotifier,
              _inspectorStateNotifier,
            ],
            builder: (context) {
              Widget _child = widget.child;

              if (_colorPickerStateNotifier.value ||
                  _inspectorStateNotifier.value) {
                _child = AbsorbPointer(
                  key: _absorbPointerKey,
                  child: _child,
                );
              }

              if (_colorPickerStateNotifier.value) {
                _child = RepaintBoundary(
                  key: _repaintBoundaryKey,
                  child: _child,
                );
              }

              return Listener(
                behavior: HitTestBehavior.translucent,
                onPointerUp: (e) => _onTap(e.position),
                onPointerMove: (e) => _onPointerMove(e.position),
                onPointerDown: (e) => _onPointerMove(e.position),
                child: _child,
              );
            },
          ),
        ),
        if (widget.isColorPickerEnabled)
          MultiValueListenableBuilder(
            valueListenables: [
              _selectedColorOffsetNotifier,
              _selectedColorStateNotifier,
            ],
            builder: (context) {
              final offset = _selectedColorOffsetNotifier.value;
              final color = _selectedColorStateNotifier.value;

              if (offset == null || color == null) {
                return const SizedBox.shrink();
              }

              return Positioned(
                left: offset.dx + 8.0,
                top: offset.dy - 64.0,
                child: ColorPickerOverlay(
                  color: color,
                ),
              );
            },
          ),
        if (widget.isWidgetInspectorEnabled)
          MultiValueListenableBuilder(
            valueListenables: [
              _currentRenderBoxNotifier,
              _inspectorStateNotifier,
            ],
            builder: (context) => LayoutBuilder(
              builder: (context, constraints) => _inspectorStateNotifier.value
                  ? InspectorOverlay(
                      size: constraints.biggest,
                      boxInfo: _currentRenderBoxNotifier.value,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        if (widget.isPanelVisible)
          Align(
            alignment: Alignment.centerRight,
            child: MultiValueListenableBuilder(
              valueListenables: [
                _inspectorStateNotifier,
                _colorPickerStateNotifier,
                _byteDataStateNotifier,
              ],
              builder: (context) => InspectorPanel(
                isInspectorEnabled: _inspectorStateNotifier.value,
                isColorPickerEnabled: _colorPickerStateNotifier.value,
                onInspectorStateChanged: _onInspectorStateChanged,
                onColorPickerStateChanged: _onColorPickerStateChanged,
                isColorPickerLoading: _byteDataStateNotifier.value == null &&
                    _colorPickerStateNotifier.value,
              ),
            ),
          ),
      ],
    );
  }
}
