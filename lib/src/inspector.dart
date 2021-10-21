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
              targetRenderBox: value?.targetRenderBox,
              containerRenderBox: value?.containerRenderBox,
            ),
          ),
        ),
      ],
    );
  }
}
