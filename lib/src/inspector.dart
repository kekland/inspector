import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:inspect/src/overlay/overlay.dart';
import 'package:inspect/src/utils.dart';

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
    required this.renderBox,
    this.outerRenderBox,
  });

  factory _CurrentRenderBoxInformation.fromHitTestResults(
    Iterable<RenderBox> boxes,
  ) {
    RenderBox? renderBox;
    RenderBox? outerRenderBox;

    for (final box in boxes) {
      renderBox ??= box;

      if (renderBox.size < box.size) {
        outerRenderBox = box;
        break;
      }
    }

    return _CurrentRenderBoxInformation(
      renderBox: renderBox!,
      outerRenderBox: outerRenderBox,
    );
  }

  final RenderBox renderBox;
  final RenderBox? outerRenderBox;

  Rect get renderBoxRect =>
      renderBox.localToGlobal(Offset.zero) & renderBox.size;

  Rect? get outerRenderBoxRect => outerRenderBox != null
      ? outerRenderBox!.localToGlobal(Offset.zero) & outerRenderBox!.size
      : null;

  bool get attached => renderBox.attached;
}

class _InspectorState extends State<Inspector> {
  final _currentRenderBoxNotifier =
      ValueNotifier<_CurrentRenderBoxInformation?>(null);

  void _onTap(Offset pointerOffset) {
    final boxes = InspectorUtils.onTap(context, pointerOffset);
    _currentRenderBoxNotifier.value =
        _CurrentRenderBoxInformation.fromHitTestResults(boxes);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Builder(
          builder: (context) => GestureDetector(
            onTapUp: (v) => _onTap(v.globalPosition),
            child: widget.child,
          ),
        ),
        ValueListenableBuilder(
          valueListenable: _currentRenderBoxNotifier,
          builder: (context, _CurrentRenderBoxInformation? value, _) =>
              LayoutBuilder(
            builder: (context, constraints) => InspectorOverlay(
              size: constraints.biggest,
              renderBox: value?.renderBox,
              outerRenderBox: value?.outerRenderBox,
            ),
          ),
        ),
      ],
    );
  }
}
