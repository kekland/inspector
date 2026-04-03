import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:inspector/src/inspector_controller.dart';
import 'package:inspector/src/widgets/ignore_tap_gesture.dart';
import 'package:inspector/src/widgets/zoom/zoom_overlay.dart';
import 'package:inspector/src/widgets/zoomable_color_picker/zoomable_color_picker.dart';

import './widgets/panel/inspector_panel.dart';
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
/// [isPanelVisible] controls the visibility of the control panel - setting it
/// to [false] will hide the panel, but the other functionality can still be
/// accessed through keyboard shortcuts. If you want to disable the inspector
/// entirely, use [isEnabled].
class Inspector extends StatefulWidget {
  const Inspector({
    Key? key,
    required this.child,
    this.controller,
    this.alignment = Alignment.center,
    this.isPanelVisible = true,
    this.isEnabled,
    this.panelBuilder,
  }) : super(key: key);

  final Widget child;
  final InspectorController? controller;
  final bool isPanelVisible;
  final Alignment alignment;
  final bool? isEnabled;
  final Widget Function(
          BuildContext context, InspectorController controller, Widget child)?
      panelBuilder;

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

  void togglePanelVisibility() =>
      setState(() => _isPanelVisible = !_isPanelVisible);

  late InspectorController _controller;
  InspectorController get controller => _controller;

  static const double _overlayMinSize = 128;
  static const double _overlayMaxSize = 246;
  static const double _overlayOffsetY = 16;

  @override
  void initState() {
    _isPanelVisible = widget.isPanelVisible;
    super.initState();

    _controller = widget.controller ??
        InspectorController(
          isEnabled: _isEnabled,
        );

    if (_isEnabled) {
      _controller.registerKeyboardHandler();
    }
  }

  @override
  void didUpdateWidget(covariant Inspector oldWidget) {
    if (oldWidget.isEnabled != widget.isEnabled ||
        oldWidget.controller != widget.controller) {
      if (oldWidget.controller == null && widget.controller != null) {
        _controller.dispose();
      }

      if (widget.controller != null) {
        _controller = widget.controller!;
        if (_isEnabled) {
          _controller.registerKeyboardHandler();
        }
      } else if (oldWidget.controller != null) {
        _controller = InspectorController(isEnabled: _isEnabled);
        if (_isEnabled) {
          _controller.registerKeyboardHandler();
        }
      }
    }

    super.didUpdateWidget(oldWidget);

    if (widget.isPanelVisible != oldWidget.isPanelVisible) {
      _isPanelVisible = widget.isPanelVisible;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
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

    final content = Stack(
      key: _controller.stackKey,
      children: [
        Align(
          alignment: widget.alignment,
          child: ValueListenableBuilder<InspectorMode>(
            valueListenable: _controller.modeNotifier,
            builder: (context, mode, _) {
              Widget _child = widget.child;

              final isIgnoringPointer = mode != InspectorMode.none;

              return MouseRegion(
                onExit: (e) => _controller.onPointerExit(e.position),
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerUp: (e) => _controller.onTap(e.position, context),
                  onPointerMove: (e) =>
                      _controller.onPointerMove(e.position, context),
                  onPointerDown: (e) =>
                      _controller.onPointerMove(e.position, context),
                  onPointerHover: (e) =>
                      _controller.onPointerHoverDebounced(e.position, context),
                  onPointerSignal: (event) {
                    if (event is PointerScrollEvent) {
                      _controller.onPointerScroll(event);
                    }
                  },
                  child: RepaintBoundary(
                    key: controller.repaintBoundaryKey,
                    child: Stack(
                      children: [
                        KeyedSubtree(
                          key: controller.ignoringPointerKey,
                          child: _child,
                        ),
                        if (isIgnoringPointer)
                          const Positioned.fill(
                            child: IgnoreTapGesture(),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        MultiValueListenableBuilder(
          valueListenables: [
            _controller.modeNotifier,
            _controller.selectedColorOffsetNotifier,
            _controller.selectedColorStateNotifier,
            _controller.zoomScaleNotifier,
          ],
          builder: (context) {
            final mode = _controller.modeNotifier.value;
            if (mode != InspectorMode.colorPicker) {
              return const SizedBox.shrink();
            }

            final offset = _controller.selectedColorOffsetNotifier.value;
            final color = _controller.selectedColorStateNotifier.value;
            final zoomScale = _controller.zoomScaleNotifier.value;
            final screenSize = MediaQuery.sizeOf(context);
            final overlaySize = ui.lerpDouble(
              _overlayMinSize,
              _overlayMaxSize,
              ((zoomScale - 2.0) / 10.0).clamp(0, 1),
            )!;

            if (offset == null || color == null) {
              return const SizedBox.shrink();
            }

            return Positioned(
              left: offset.dx.clamp(0, screenSize.width - overlaySize),
              top: (offset.dy - overlaySize - _overlayOffsetY)
                  .clamp(0, screenSize.height),
              child: ZoomableColorPickerOverlay(
                color: color,
                isColorSchemeHintEnabled: _controller.isColorSchemeHintEnabled,
                image: _controller.image!,
                imageOffset:
                    _controller.selectedColorImageOffsetNotifier.value ??
                        Offset.zero,
                overlaySize: overlaySize,
                zoomScale: zoomScale,
                pixelRatio: MediaQuery.devicePixelRatioOf(context),
              ),
            );
          },
        ),
        MultiValueListenableBuilder(
          valueListenables: [
            _controller.modeNotifier,
            _controller.currentRenderBoxNotifier,
            _controller.hoveredRenderBoxNotifier,
            _controller.comparedRenderBoxNotifier,
          ],
          builder: (context) {
            final mode = _controller.modeNotifier.value;
            if (mode != InspectorMode.inspector &&
                mode != InspectorMode.inspectAndCompare &&
                mode != InspectorMode.compareSelect) {
              return const SizedBox.shrink();
            }

            return LayoutBuilder(
              builder: (context, constraints) => InspectorOverlay(
                size: constraints.biggest,
                boxInfo: _controller.currentRenderBoxNotifier.value,
                hoveredBoxInfo: _controller.hoveredRenderBoxNotifier.value,
                comparedBoxInfo: _controller.comparedRenderBoxNotifier.value,
              ),
            );
          },
        ),
        MultiValueListenableBuilder(
          valueListenables: [
            _controller.modeNotifier,
            _controller.zoomImageOffsetNotifier,
            _controller.zoomOverlayOffsetNotifier,
            _controller.byteDataStateNotifier,
            _controller.zoomScaleNotifier,
          ],
          builder: (context) {
            final mode = _controller.modeNotifier.value;
            if (mode != InspectorMode.zoom) return const SizedBox.shrink();

            final offset = _controller.zoomOverlayOffsetNotifier.value;
            final imageOffset = _controller.zoomImageOffsetNotifier.value;
            final byteData = _controller.byteDataStateNotifier.value;
            final zoomScale = _controller.zoomScaleNotifier.value;

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
                  image: _controller.image!,
                  imageOffset: imageOffset,
                  overlaySize: overlaySize,
                  zoomScale: zoomScale,
                  pixelRatio: MediaQuery.of(context).devicePixelRatio,
                ),
              ),
            );
          },
        ),
      ],
    );

    if (widget.panelBuilder != null) {
      return widget.panelBuilder!(context, _controller, content);
    }

    return Stack(
      children: [
        content,
        if (_isPanelVisible)
          Align(
            alignment: Alignment.centerRight,
            child: ValueListenableBuilder<InspectorMode>(
              valueListenable: _controller.modeNotifier,
              builder: (context, mode, _) => InspectorPanel(
                controller: _controller,
              ),
            ),
          ),
      ],
    );
  }
}
