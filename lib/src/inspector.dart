import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:inspect/src/widgets/multi_value_listenable.dart';
import './widgets/overlay/overlay.dart';
import './widgets/panel/inspector_panel.dart';
import 'utils.dart';

class Inspector extends StatefulWidget {
  const Inspector({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  _InspectorState createState() => _InspectorState();
}

class _CurrentRenderBoxInformation {
  _CurrentRenderBoxInformation({
    required this.targetRenderBox,
    this.containerRenderBox,
  });

  factory _CurrentRenderBoxInformation.fromHitTestResults(
    Iterable<RenderBox> boxes,
  ) {
    RenderBox? targetRenderBox;
    RenderBox? containerRenderBox;

    for (final box in boxes) {
      targetRenderBox ??= box;

      if (targetRenderBox.size < box.size) {
        containerRenderBox = box;
        break;
      }
    }

    return _CurrentRenderBoxInformation(
      targetRenderBox: targetRenderBox!,
      containerRenderBox: containerRenderBox,
    );
  }

  final RenderBox targetRenderBox;
  final RenderBox? containerRenderBox;
}

class _InspectorState extends State<Inspector> {
  final _listenerKey = const ValueKey('listener-key');
  final _repaintBoundaryKey = GlobalKey();
  ui.Image? _image;
  ByteData? _byteData;

  final _currentRenderBoxNotifier =
      ValueNotifier<_CurrentRenderBoxInformation?>(null);

  final _inspectorStateNotifier = ValueNotifier<bool>(false);
  final _colorPickerStateNotifier = ValueNotifier<bool>(false);

  final _selectedColorOffsetNotifier = ValueNotifier<Offset?>(null);
  final _selectedColorStateNotifier = ValueNotifier<Color?>(null);

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

    final boxes = InspectorUtils.onTap(context, pointerOffset);
    _currentRenderBoxNotifier.value =
        _CurrentRenderBoxInformation.fromHitTestResults(boxes);
  }

  void _onPointerMove(Offset pointerOffset) {
    if (_colorPickerStateNotifier.value) {
      _onHover(pointerOffset);
    }
  }

  void _onInspectorStateChanged(bool isEnabled) {
    if (!isEnabled) {
      _currentRenderBoxNotifier.value = null;
    }

    _inspectorStateNotifier.value = isEnabled;

    if (isEnabled) {
      _colorPickerStateNotifier.value = false;
    }
  }

  void _onColorPickerStateChanged(bool isEnabled) {
    _colorPickerStateNotifier.value = isEnabled;

    if (isEnabled) {
      _inspectorStateNotifier.value = false;
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        _extractByteData();
      });
    } else {
      if (_selectedColorStateNotifier.value != null) {
        final color = _selectedColorStateNotifier.value!;
        final colorString = '#${colorToHexString(color)}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  width: 16.0,
                  height: 16.0,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
                const SizedBox(width: 8.0),
                Text('Color: $colorString'),
              ],
            ),
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: colorString));
              },
            ),
          ),
        );
      }

      _image?.dispose();
      _byteData = null;

      _selectedColorOffsetNotifier.value = null;
      _selectedColorStateNotifier.value = null;
    }
  }

  Future<void> _extractByteData() async {
    final boundary = _repaintBoundaryKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;

    _image = await boundary.toImage();
    _byteData = await _image!.toByteData();
  }

  void _onHover(Offset offset) {
    if (_image == null || _byteData == null) return;

    final _x = offset.dx.round();
    final _y = offset.dy.round();

    final _index = (_y * _image!.width + _x) * 4;

    final r = _byteData!.getUint8(_index);
    final g = _byteData!.getUint8(_index + 1);
    final b = _byteData!.getUint8(_index + 2);
    final a = _byteData!.getUint8(_index + 3);

    _selectedColorStateNotifier.value = Color.fromARGB(a, r, g, b);
    _selectedColorOffsetNotifier.value = offset;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ValueListenableBuilder(
          valueListenable: _colorPickerStateNotifier,
          builder: (context, bool isPickingColor, child) {
            Widget _child = child!;

            if (_colorPickerStateNotifier.value) {
              _child = RepaintBoundary(
                key: _repaintBoundaryKey,
                child: AbsorbPointer(
                  child: _child,
                ),
              );
            }

            return GestureDetector(
              key: _listenerKey,
              behavior: HitTestBehavior.translucent,
              onTapUp: (e) => _onTap(e.globalPosition),
              onPanUpdate: (e) => _onPointerMove(e.globalPosition),
              onPanEnd: (e) => _onTap(null),
              child: _child,
            );
          },
          child: widget.child,
        ),
        MultiValueListenableBuilder(
          valueListenables: [
            _selectedColorOffsetNotifier,
            _selectedColorStateNotifier,
          ],
          builder: (context) {
            final offset = _selectedColorOffsetNotifier.value;
            final color = _selectedColorStateNotifier.value;

            if (offset == null || color == null) return const SizedBox.shrink();

            final color2 = color;
            return Positioned(
              left: offset.dx + 8.0,
              top: offset.dy - 64.0,
              child: Container(
                width: 56.0,
                height: 56.0,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(
                    color: Colors.black12,
                  ),
                ),
                alignment: Alignment.bottomRight,
                child: Material(
                  type: MaterialType.transparency,
                  child: Text(
                    colorToHexString(color),
                    style: TextStyle(
                      color: getTextColorOnBackground(color2),
                      fontSize: 12.0,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        MultiValueListenableBuilder(
          valueListenables: [
            _currentRenderBoxNotifier,
            _inspectorStateNotifier,
          ],
          builder: (context) => LayoutBuilder(
            builder: (context, constraints) => _inspectorStateNotifier.value
                ? InspectorOverlay(
                    size: constraints.biggest,
                    targetRenderBox:
                        _currentRenderBoxNotifier.value?.targetRenderBox,
                    containerRenderBox:
                        _currentRenderBoxNotifier.value?.containerRenderBox,
                  )
                : const SizedBox.shrink(),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: MultiValueListenableBuilder(
            valueListenables: [
              _inspectorStateNotifier,
              _colorPickerStateNotifier,
            ],
            builder: (context) => InspectorPanel(
              isInspectorEnabled: _inspectorStateNotifier.value,
              isColorPickerEnabled: _colorPickerStateNotifier.value,
              onInspectorStateChanged: _onInspectorStateChanged,
              onColorPickerStateChanged: _onColorPickerStateChanged,
            ),
          ),
        ),
      ],
    );
  }
}
