import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:inspector/src/keyboard_handler.dart';
import 'package:inspector/src/widgets/zoom/zoom_overlay.dart';

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
    this.isZoomEnabled = true,
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
    this.zoomShortcuts = const [
      LogicalKeyboardKey.keyZ,
    ],
    this.isEnabled,
  }) : super(key: key);

  final Widget child;
  final bool areKeyboardShortcutsEnabled;
  final bool isPanelVisible;
  final bool isWidgetInspectorEnabled;
  final bool isColorPickerEnabled;
  final bool isZoomEnabled;
  final Alignment alignment;
  final List<LogicalKeyboardKey> widgetInspectorShortcuts;
  final List<LogicalKeyboardKey> colorPickerShortcuts;
  final List<LogicalKeyboardKey> zoomShortcuts;
  final bool? isEnabled;

  static InspectorState of(BuildContext context) {
    final InspectorState? result = maybeOf(context);
    if (result != null) {
      return result;
    }
    throw FlutterError.fromParts([
      ErrorSummary(
        "Inspector.of() error.",
      ),
      context.describeElement("the context"),
    ]);
  }

  static InspectorState? maybeOf(BuildContext? context) {
    return context?.findAncestorStateOfType<InspectorState>();
  }

  @override
  InspectorState createState() => InspectorState();
}

class InspectorState extends State<Inspector> {
  bool _isPanelVisible = false;
  bool get isPanelVisible => _isPanelVisible;

  void togglePanelVisibility() => setState(() => _isPanelVisible = !_isPanelVisible);

  final _stackKey = GlobalKey();
  final _repaintBoundaryKey = GlobalKey();
  final _absorbPointerKey = GlobalKey();
  ui.Image? _image;

  final _byteDataStateNotifier = ValueNotifier<ByteData?>(null);

  final _currentRenderBoxNotifier = ValueNotifier<BoxInfo?>(null);

  final _inspectorStateNotifier = ValueNotifier<bool>(false);
  final _colorPickerStateNotifier = ValueNotifier<bool>(false);
  final _zoomStateNotifier = ValueNotifier<bool>(false);

  final _selectedColorOffsetNotifier = ValueNotifier<Offset?>(null);
  final _selectedColorStateNotifier = ValueNotifier<Color?>(null);

  final _zoomImageOffsetNotifier = ValueNotifier<Offset?>(null);
  final _zoomScaleNotifier = ValueNotifier<double>(2.0);
  final _zoomOverlayOffsetNotifier = ValueNotifier<Offset?>(null);

  late final KeyboardHandler _keyboardHandler;

  Offset? _pointerHoverPosition;

  @override
  void initState() {
    _isPanelVisible = widget.isPanelVisible;
    super.initState();

    _keyboardHandler = KeyboardHandler(
      onInspectorStateChanged: _onInspectorStateChanged,
      onColorPickerStateChanged: _onColorPickerStateChanged,
      onZoomStateChanged: _onZoomStateChanged,
      colorPickerStateKeys: widget.colorPickerShortcuts,
      inspectorStateKeys: widget.widgetInspectorShortcuts,
      zoomStateKeys: widget.zoomShortcuts,
    );

    if (_isEnabled && widget.areKeyboardShortcutsEnabled) {
      _keyboardHandler.register();
    }
  }

  // Gestures

  void _onTap(Offset? pointerOffset) {
    if (_colorPickerStateNotifier.value) {
      if (pointerOffset != null) {
        _onColorPickerHover(pointerOffset);
      }

      _onColorPickerStateChanged(false);
      return;
    }

    if (_zoomStateNotifier.value) {
      _onZoomStateChanged(false);
      return;
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
    _pointerHoverPosition = pointerOffset;

    if (_colorPickerStateNotifier.value) {
      _onColorPickerHover(pointerOffset);
    }

    if (_zoomStateNotifier.value) {
      _onZoomHover(pointerOffset);
    }
  }

  void _onPointerHover(Offset pointerOffset) {
    _pointerHoverPosition = pointerOffset;
    if (_zoomStateNotifier.value) {
      _onZoomHover(pointerOffset);
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
      _onZoomStateChanged(false);
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
      _onZoomStateChanged(false);

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

  // Zoom

  void _onZoomStateChanged(bool isEnabled) {
    if (!widget.isZoomEnabled) {
      _zoomStateNotifier.value = false;
      return;
    }

    _zoomStateNotifier.value = isEnabled;

    if (isEnabled) {
      _onInspectorStateChanged(false);
      _onColorPickerStateChanged(false);
      _zoomScaleNotifier.value = 2.0;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _extractByteData();

        if (_pointerHoverPosition != null) {
          _onZoomHover(_pointerHoverPosition!);
        }
      });
    } else {
      _image?.dispose();
      _image = null;
      _byteDataStateNotifier.value = null;

      _zoomImageOffsetNotifier.value = null;
      _zoomOverlayOffsetNotifier.value = null;
      _zoomScaleNotifier.value = 2.0;
    }
  }

  Future<void> _extractByteData() async {
    if (_image != null) return;
    final boundary = _repaintBoundaryKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;

    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    _image = await boundary.toImage(pixelRatio: pixelRatio);
    _byteDataStateNotifier.value = await _image!.toByteData();
  }

  Offset _extractShiftedOffset(Offset offset) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    var _offset = (_repaintBoundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary)
        .globalToLocal(offset);

    _offset *= pixelRatio;

    return _offset;
  }

  void _onColorPickerHover(Offset offset) {
    if (_image == null || _byteDataStateNotifier.value == null) return;

    final shiftedOffset = _extractShiftedOffset(offset);
    final _x = shiftedOffset.dx.round();
    final _y = shiftedOffset.dy.round();

    _selectedColorStateNotifier.value = getPixelFromByteData(
      _byteDataStateNotifier.value!,
      width: _image!.width,
      x: _x,
      y: _y,
    );

    final overlayOffset =
        (_stackKey.currentContext!.findRenderObject() as RenderStack)
            .localToGlobal(Offset.zero);

    _selectedColorOffsetNotifier.value = offset - overlayOffset;
  }

  void _onZoomHover(Offset offset) {
    if (_image == null || _byteDataStateNotifier.value == null) return;

    final shiftedOffset = _extractShiftedOffset(offset);

    final overlayOffset =
        (_stackKey.currentContext!.findRenderObject() as RenderStack)
            .localToGlobal(Offset.zero);

    _zoomImageOffsetNotifier.value = shiftedOffset;
    _zoomOverlayOffsetNotifier.value = offset - overlayOffset;
  }

  void _onPointerScroll(PointerScrollEvent scrollEvent) {
    if (_zoomStateNotifier.value) {
      final newValue =
          _zoomScaleNotifier.value + 1.0 * -scrollEvent.scrollDelta.dy.sign;

      if (newValue < 1.0) {
        return;
      }

      _zoomScaleNotifier.value = newValue;
    }
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

    if (widget.isPanelVisible != oldWidget.isPanelVisible) {
      _isPanelVisible = widget.isPanelVisible;
    }
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
              _zoomStateNotifier,
            ],
            builder: (context) {
              Widget _child = widget.child;

              final isAbsorbingPointer = _colorPickerStateNotifier.value ||
                  _inspectorStateNotifier.value ||
                  _zoomStateNotifier.value;

              return Listener(
                behavior: HitTestBehavior.translucent,
                onPointerUp: (e) => _onTap(e.position),
                onPointerMove: (e) => _onPointerMove(e.position),
                onPointerDown: (e) => _onPointerMove(e.position),
                onPointerHover: (e) => _onPointerHover(e.position),
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    _onPointerScroll(event);
                  }
                },
                child: RepaintBoundary(
                  key: _repaintBoundaryKey,
                  child: AbsorbPointer(
                    key: _absorbPointerKey,
                    absorbing: isAbsorbingPointer,
                    child: _child,
                  ),
                ),
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
              _zoomStateNotifier,
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
        if (widget.isZoomEnabled)
          MultiValueListenableBuilder(
            valueListenables: [
              _zoomImageOffsetNotifier,
              _zoomOverlayOffsetNotifier,
              _byteDataStateNotifier,
              _zoomScaleNotifier,
            ],
            builder: (context) {
              final offset = _zoomOverlayOffsetNotifier.value;
              final imageOffset = _zoomImageOffsetNotifier.value;
              final byteData = _byteDataStateNotifier.value;
              final zoomScale = _zoomScaleNotifier.value;

              if (offset == null || byteData == null || imageOffset == null) {
                return const SizedBox.shrink();
              }

              final overlaySize = ui
                  .lerpDouble(
                    128.0,
                    256.0,
                    ((zoomScale - 2.0) / 10.0).clamp(0, 1),
                  )!
                  .toDouble();

              return Positioned(
                left: offset.dx - overlaySize / 2,
                top: offset.dy - overlaySize / 2,
                child: IgnorePointer(
                  child: ZoomOverlayWidget(
                    image: _image!,
                    overlayOffset: offset,
                    imageOffset: imageOffset,
                    overlaySize: overlaySize,
                    zoomScale: zoomScale,
                    pixelRatio: MediaQuery.of(context).devicePixelRatio,
                  ),
                ),
              );
            },
          ),
        if (_isPanelVisible)
          Align(
            alignment: Alignment.centerRight,
            child: MultiValueListenableBuilder(
              valueListenables: [
                _inspectorStateNotifier,
                _colorPickerStateNotifier,
                _zoomStateNotifier,
                _byteDataStateNotifier,
              ],
              builder: (context) => InspectorPanel(
                isInspectorEnabled: _inspectorStateNotifier.value,
                isColorPickerEnabled: _colorPickerStateNotifier.value,
                isZoomEnabled: _zoomStateNotifier.value,
                onInspectorStateChanged: _onInspectorStateChanged,
                onColorPickerStateChanged: _onColorPickerStateChanged,
                onZoomStateChanged: _onZoomStateChanged,
                isColorPickerLoading: _byteDataStateNotifier.value == null &&
                    _colorPickerStateNotifier.value,
                isZoomLoading: _byteDataStateNotifier.value == null &&
                    _zoomStateNotifier.value,
              ),
            ),
          ),
      ],
    );
  }
}
