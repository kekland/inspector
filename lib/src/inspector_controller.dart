import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'keyboard_handler.dart';
import 'utils.dart';
import 'widgets/color_picker/color_picker_snackbar.dart';
import 'widgets/color_picker/utils.dart';
import 'widgets/inspector/box_info.dart';

enum InspectorMode {
  none,
  inspector,
  inspectAndCompare,
  colorPicker,
  zoom,
}

class InspectorController {
  InspectorController({
    this.isEnabled = true,
    this.isWidgetInspectorEnabled = true,
    this.isWidgetInspectAndCompareEnabled = true,
    this.isColorPickerEnabled = true,
    this.isColorSchemeHintEnabled = true,
    this.isZoomEnabled = true,
    this.widgetInspectorShortcuts = const [
      LogicalKeyboardKey.alt,
      LogicalKeyboardKey.altLeft,
      LogicalKeyboardKey.altRight,
      LogicalKeyboardKey.meta,
      LogicalKeyboardKey.metaLeft,
      LogicalKeyboardKey.metaRight,
    ],
    this.widgetInspectAndCompareShortcuts = const [
      LogicalKeyboardKey.keyY,
    ],
    this.colorPickerShortcuts = const [
      LogicalKeyboardKey.shift,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.shiftRight,
    ],
    this.zoomShortcuts = const [
      LogicalKeyboardKey.keyZ,
    ],
  }) {
    _keyboardHandler = KeyboardHandler(
      onInspectorStateChanged: (v) => _toggleMode(v, InspectorMode.inspector),
      onInspectAndCompareChanged: (v) =>
          _toggleMode(v, InspectorMode.inspectAndCompare),
      onColorPickerStateChanged: (v) =>
          _toggleMode(v, InspectorMode.colorPicker),
      onZoomStateChanged: (v) => _toggleMode(v, InspectorMode.zoom),
      colorPickerStateKeys: colorPickerShortcuts,
      inspectorStateKeys: widgetInspectorShortcuts,
      inspectAndCompareKeys: widgetInspectAndCompareShortcuts,
      zoomStateKeys: zoomShortcuts,
    );
  }

  final bool isEnabled;
  final bool isWidgetInspectorEnabled;
  final bool isWidgetInspectAndCompareEnabled;
  final bool isColorPickerEnabled;
  final bool isColorSchemeHintEnabled;
  final bool isZoomEnabled;

  final List<LogicalKeyboardKey> widgetInspectorShortcuts;
  final List<LogicalKeyboardKey> widgetInspectAndCompareShortcuts;
  final List<LogicalKeyboardKey> colorPickerShortcuts;
  final List<LogicalKeyboardKey> zoomShortcuts;

  final GlobalKey stackKey = GlobalKey();
  final GlobalKey repaintBoundaryKey = GlobalKey();
  final GlobalKey ignoringPointerKey = GlobalKey();

  final modeNotifier = ValueNotifier<InspectorMode>(InspectorMode.none);

  final byteDataStateNotifier = ValueNotifier<ByteData?>(null);

  final currentRenderBoxNotifier = ValueNotifier<BoxInfo?>(null);
  final hoveredRenderBoxNotifier = ValueNotifier<BoxInfo?>(null);
  final comparedRenderBoxNotifier = ValueNotifier<BoxInfo?>(null);

  final selectedColorOffsetNotifier = ValueNotifier<Offset?>(null);
  final selectedColorStateNotifier = ValueNotifier<Color?>(null);
  final selectedColorImageOffsetNotifier = ValueNotifier<Offset?>(null);

  final zoomImageOffsetNotifier = ValueNotifier<Offset?>(null);
  final zoomScaleNotifier = ValueNotifier<double>(2.0);
  final zoomOverlayOffsetNotifier = ValueNotifier<Offset?>(null);

  ui.Image? _image;
  ui.Image? get image => _image;
  Offset? _pointerHoverPosition;
  Timer? _onPointerHoverDebounce;
  late final KeyboardHandler _keyboardHandler;

  void registerKeyboardHandler() {
    _keyboardHandler.register();
  }

  void unregisterKeyboardHandler() {
    _keyboardHandler.dispose();
  }

  void dispose() {
    _image?.dispose();
    modeNotifier.dispose();
    byteDataStateNotifier.dispose();
    currentRenderBoxNotifier.dispose();
    hoveredRenderBoxNotifier.dispose();
    comparedRenderBoxNotifier.dispose();
    selectedColorOffsetNotifier.dispose();
    selectedColorStateNotifier.dispose();
    selectedColorImageOffsetNotifier.dispose();
    zoomImageOffsetNotifier.dispose();
    zoomScaleNotifier.dispose();
    zoomOverlayOffsetNotifier.dispose();
    _onPointerHoverDebounce?.cancel();
    _keyboardHandler.dispose();
  }

  void _toggleMode(bool enable, InspectorMode targetMode) {
    if (enable) {
      setMode(targetMode);
    } else if (modeNotifier.value == targetMode) {
      // Special case: when releasing Y key in inspectAndCompare mode,
      // return to inspector mode instead of none
      if (targetMode == InspectorMode.inspectAndCompare) {
        setMode(InspectorMode.inspector);
      } else {
        setMode(InspectorMode.none);
      }
    }
  }

  void setMode(InspectorMode mode, {BuildContext? context}) {
    if (mode == modeNotifier.value) return;

    // Check if mode is enabled
    switch (mode) {
      case InspectorMode.inspector:
        if (!isWidgetInspectorEnabled) return;
        break;
      case InspectorMode.inspectAndCompare:
        if (!isWidgetInspectorEnabled || !isWidgetInspectAndCompareEnabled) {
          return;
        }
        break;
      case InspectorMode.colorPicker:
        if (!isColorPickerEnabled) return;
        break;
      case InspectorMode.zoom:
        if (!isZoomEnabled) return;
        break;
      case InspectorMode.none:
        break;
    }

    // Cleanup previous mode
    _cleanupMode(modeNotifier.value, mode, context);

    modeNotifier.value = mode;

    // Setup new mode
    _setupMode(mode);
  }

  void _cleanupMode(
      InspectorMode oldMode, InspectorMode newMode, BuildContext? context) {
    switch (oldMode) {
      case InspectorMode.inspector:
      case InspectorMode.inspectAndCompare:
        // Don't cleanup when switching between inspector and inspectAndCompare
        // because they share the same state (currentRenderBox)
        if (newMode != InspectorMode.inspector &&
            newMode != InspectorMode.inspectAndCompare) {
          currentRenderBoxNotifier.value = null;
          hoveredRenderBoxNotifier.value = null;
          comparedRenderBoxNotifier.value = null;
        } else {
          // Only clear hover and compare when staying in inspector modes
          hoveredRenderBoxNotifier.value = null;
          comparedRenderBoxNotifier.value = null;
        }
        break;
      case InspectorMode.colorPicker:
        if (selectedColorStateNotifier.value != null && context != null) {
          showColorPickerResultSnackbar(
            context: context,
            color: selectedColorStateNotifier.value!,
          );
        }
        _cleanupImage();
        selectedColorOffsetNotifier.value = null;
        selectedColorStateNotifier.value = null;
        selectedColorImageOffsetNotifier.value = null;
        break;
      case InspectorMode.zoom:
        _cleanupImage();
        zoomImageOffsetNotifier.value = null;
        zoomOverlayOffsetNotifier.value = null;
        zoomScaleNotifier.value = 2.0;
        break;
      case InspectorMode.none:
        break;
    }
  }

  void _setupMode(InspectorMode mode) {
    switch (mode) {
      case InspectorMode.inspector:
      case InspectorMode.inspectAndCompare:
        break;
      case InspectorMode.colorPicker:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _extractByteData();
        });
        break;
      case InspectorMode.zoom:
        zoomScaleNotifier.value = 2.0;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _extractByteData();
          if (_pointerHoverPosition != null &&
              stackKey.currentContext != null) {
            _onZoomHover(_pointerHoverPosition!, stackKey.currentContext!);
          }
        });
        break;
      case InspectorMode.none:
        break;
    }
  }

  void _cleanupImage() {
    _image?.dispose();
    _image = null;
    byteDataStateNotifier.value = null;
  }

  void onTap(Offset? pointerOffset, BuildContext context) {
    final mode = modeNotifier.value;
    if (mode == InspectorMode.none) return;

    if (mode == InspectorMode.colorPicker) {
      if (pointerOffset != null) {
        _onColorPickerHover(pointerOffset, context);
      }
      setMode(InspectorMode.none, context: context);
      return;
    }

    if (mode == InspectorMode.zoom) {
      setMode(InspectorMode.none);
      return;
    }

    if (mode == InspectorMode.inspector ||
        mode == InspectorMode.inspectAndCompare) {
      if (pointerOffset == null) return;
      hoveredRenderBoxNotifier.value = null;
      comparedRenderBoxNotifier.value = null;
      currentRenderBoxNotifier.value = _computeBoxInfoAt(
        pointerOffset,
        findContainer: true,
      );
    }
  }

  void onPointerMove(Offset pointerOffset, BuildContext context) {
    _pointerHoverPosition = pointerOffset;
    final mode = modeNotifier.value;

    if (mode == InspectorMode.colorPicker) {
      _onColorPickerHover(pointerOffset, context);
    } else if (mode == InspectorMode.zoom) {
      _onZoomHover(pointerOffset, context);
    }
  }

  void onPointerHoverDebounced(Offset pointerOffset, BuildContext context) {
    if (_onPointerHoverDebounce?.isActive ?? false) return;
    _onPointerHoverDebounce = Timer(
      const Duration(milliseconds: 0),
      () => _onPointerHover(pointerOffset),
    );
  }

  void _onPointerHover(Offset pointerOffset) {
    _pointerHoverPosition = pointerOffset;
    final mode = modeNotifier.value;

    if (mode == InspectorMode.zoom) {
      final context = stackKey.currentContext;
      if (context != null) {
        _onZoomHover(pointerOffset, context);
      }
      return;
    }

    if (mode == InspectorMode.inspector ||
        mode == InspectorMode.inspectAndCompare) {
      if (mode == InspectorMode.inspectAndCompare) {
        hoveredRenderBoxNotifier.value = null;
        final compare = _computeBoxInfoAt(pointerOffset);
        if (compare?.targetRenderBox !=
            currentRenderBoxNotifier.value?.targetRenderBox) {
          comparedRenderBoxNotifier.value = compare;
        } else {
          comparedRenderBoxNotifier.value = null;
        }
      } else {
        final hover = _computeBoxInfoAt(pointerOffset);
        if (hover?.targetRenderBox !=
            currentRenderBoxNotifier.value?.targetRenderBox) {
          hoveredRenderBoxNotifier.value = hover;
        } else {
          hoveredRenderBoxNotifier.value = null;
        }
      }
    }
  }

  void onPointerExit(Offset pointerOffset) {
    hoveredRenderBoxNotifier.value = null;
  }

  void onPointerScroll(PointerScrollEvent scrollEvent) {
    if (modeNotifier.value == InspectorMode.zoom) {
      final newValue =
          zoomScaleNotifier.value + 1.0 * -scrollEvent.scrollDelta.dy.sign;

      if (newValue < 1.0) {
        return;
      }

      zoomScaleNotifier.value = newValue;
    }
  }

  BoxInfo? _computeBoxInfoAt(Offset offset, {bool findContainer = false}) {
    if (ignoringPointerKey.currentContext == null) return null;

    final boxes = InspectorUtils.findRenderObjectsAt(
        ignoringPointerKey.currentContext!, offset);

    if (boxes.isEmpty) return null;

    if (stackKey.currentContext == null) return null;

    final overlayOffset =
        (stackKey.currentContext!.findRenderObject() as RenderStack)
            .localToGlobal(Offset.zero);

    return BoxInfo.fromHitTestResults(
      boxes,
      overlayOffset: overlayOffset,
      findContainer: findContainer,
    );
  }

  Future<void> _extractByteData() async {
    if (_image != null) return;
    if (repaintBoundaryKey.currentContext == null) return;

    final boundary = repaintBoundaryKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;

    final context = repaintBoundaryKey.currentContext!;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    _image = await boundary.toImage(pixelRatio: pixelRatio);
    byteDataStateNotifier.value = await _image!.toByteData();
  }

  Offset _extractShiftedOffset(Offset offset, BuildContext context) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    if (repaintBoundaryKey.currentContext == null) return Offset.zero;

    var _offset = (repaintBoundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary)
        .globalToLocal(offset);

    _offset *= pixelRatio;

    return _offset;
  }

  void _onColorPickerHover(Offset offset, BuildContext context) {
    if (_image == null || byteDataStateNotifier.value == null) return;

    final shiftedOffset = _extractShiftedOffset(offset, context);
    final _x = shiftedOffset.dx.round();
    final _y = shiftedOffset.dy.round();

    final color = getPixelFromByteData(
      byteDataStateNotifier.value!,
      width: _image!.width,
      height: _image!.height,
      x: _x,
      y: _y,
    );

    if (color == null) return;

    selectedColorStateNotifier.value = color;
    selectedColorImageOffsetNotifier.value = shiftedOffset;

    if (stackKey.currentContext == null) return;

    final overlayOffset =
        (stackKey.currentContext!.findRenderObject() as RenderStack)
            .localToGlobal(Offset.zero);

    selectedColorOffsetNotifier.value = offset - overlayOffset;
  }

  void _onZoomHover(Offset offset, BuildContext context) {
    if (_image == null || byteDataStateNotifier.value == null) return;

    final shiftedOffset = _extractShiftedOffset(offset, context);

    if (stackKey.currentContext == null) return;

    final overlayOffset =
        (stackKey.currentContext!.findRenderObject() as RenderStack)
            .localToGlobal(Offset.zero);

    zoomImageOffsetNotifier.value = shiftedOffset;
    zoomOverlayOffsetNotifier.value = offset - overlayOffset;
  }
}
