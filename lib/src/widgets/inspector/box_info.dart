import 'package:flutter/rendering.dart';
import 'package:inspector/src/renderbox_extension.dart';
import 'package:inspector/src/size_extension.dart';

/// Contains information about the currently selected [RenderBox].
///
/// [containerRect] may be [null].
class BoxInfo {
  BoxInfo({
    required this.targetRenderBox,
    this.containerRenderBox,
    this.overlayOffset = Offset.zero,
    this.hitTestPath = const <RenderBox>[],
  });

  factory BoxInfo.fromHitTestResults(
    Iterable<RenderBox> boxes, {
    Offset overlayOffset = Offset.zero,
    bool findContainer = false,
  }) {
    final hitTestPath = List<RenderBox>.unmodifiable(boxes);

    RenderBox targetRenderBox = boxes.first;
    RenderBox? containerRenderBox;

    /// Used [isSmallerThan] to find the smallest box under the cursor
    for (final box in boxes) {
      if (box.size.isSmallerThan(targetRenderBox.size)) {
        targetRenderBox = box;
      }
    }

    if (findContainer) {
      /// The >= is used to check whether the item is fully contained by the other box.
      /// The isGreaterThan is used to avoid selecting the same box as the target box.
      for (final box in boxes) {
        if (box.size >= targetRenderBox.size &&
            box.size.isGreaterThan(targetRenderBox.size)) {
          if ((containerRenderBox == null ||
                  box.size.isSmallerThan(containerRenderBox.size)) &&
              targetRenderBox.isDescendantOf(box)) {
            containerRenderBox = box;
          }
        }
      }
    }

    return BoxInfo(
      targetRenderBox: targetRenderBox,
      containerRenderBox: containerRenderBox,
      overlayOffset: overlayOffset,
      hitTestPath: hitTestPath,
    );
  }

  final RenderBox targetRenderBox;
  final RenderBox? containerRenderBox;

  final Offset overlayOffset;

  /// Render boxes found under the pointer during hit-testing, in traversal order.
  ///
  /// This is intentionally kept separate from [targetRenderBox] selection logic
  /// so UI panels can derive additional context (e.g., nearest decorated box).
  final List<RenderBox> hitTestPath;

  Rect get targetRect => getRectFromRenderBox(targetRenderBox)!;

  Rect get targetRectShifted => targetRect.shift(-overlayOffset);

  Rect? get containerRect => containerRenderBox != null
      ? getRectFromRenderBox(containerRenderBox!)
      : null;

  Rect get containerRectShifted => targetRect.shift(-overlayOffset);

  double? get paddingLeft => paddingRectLeft?.width;

  double? get paddingRight => paddingRectRight?.width;

  double? get paddingTop => paddingRectTop?.height;

  double? get paddingBottom => paddingRectBottom?.height;

  Rect? get paddingRectLeft => containerRect != null
      ? Rect.fromLTRB(
          containerRect!.left,
          containerRect!.top,
          targetRect.left,
          containerRect!.bottom,
        )
      : null;

  Rect? get paddingRectTop => containerRect != null
      ? Rect.fromLTRB(
          targetRect.left,
          containerRect!.top,
          targetRect.right,
          targetRect.top,
        )
      : null;

  Rect? get paddingRectRight => containerRect != null
      ? Rect.fromLTRB(
          targetRect.right,
          containerRect!.top,
          containerRect!.right,
          containerRect!.bottom,
        )
      : null;

  Rect? get paddingRectBottom => containerRect != null
      ? Rect.fromLTRB(
          targetRect.left,
          targetRect.bottom,
          targetRect.right,
          containerRect!.bottom,
        )
      : null;

  String describePadding() {
    assert(containerRect != null);

    final _left = paddingLeft!.toStringAsFixed(1);
    final _top = paddingTop!.toStringAsFixed(1);
    final _right = paddingRight!.toStringAsFixed(1);
    final _bottom = paddingBottom!.toStringAsFixed(1);

    return '$_left, $_top, $_right, $_bottom';
  }

  bool get isDecoratedBox =>
      targetRenderBox is RenderDecoratedBox &&
      (targetRenderBox as RenderDecoratedBox).decoration is BoxDecoration;

  BoxDecoration get _decoration =>
      (targetRenderBox as RenderDecoratedBox).decoration as BoxDecoration;

  Color? getDecoratedBoxColor() {
    assert(isDecoratedBox);
    return _decoration.color;
  }

  BorderRadiusGeometry? getDecoratedBoxBorderRadius() {
    assert(isDecoratedBox);
    return _decoration.borderRadius;
  }
}

Rect? getRectFromRenderBox(RenderBox renderBox) {
  return renderBox.attached
      ? (renderBox.localToGlobal(Offset.zero)) & renderBox.size
      : null;
}

double calculateBoxPosition({
  required Rect rect,
  required double height,
  double padding = 8.0,
}) {
  final preferredHeight = height;

  // Position when the overlay is placed inside the container
  final insideTopEdge = rect.top + padding;
  final insideBottomEdge = rect.bottom - padding - preferredHeight;

  // Position when the overlay is placed above the container
  final aboveTopEdge = rect.top - padding - preferredHeight;

  // Position when the overlay is placed below the container
  final belowTopEdge = rect.bottom + padding;

  final minHeightToBeInsideContainer = (height + padding) * 2;

  final isInsideContainer = rect.height > minHeightToBeInsideContainer;

  if (isInsideContainer) {
    return (insideTopEdge > padding) ? insideTopEdge : insideBottomEdge;
  } else {
    return (aboveTopEdge > padding) ? aboveTopEdge : belowTopEdge;
  }
}
