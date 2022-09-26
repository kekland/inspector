import 'package:flutter/rendering.dart';

/// Contains information about the currently selected [RenderBox].
///
/// [containerRect] may be [null].
class BoxInfo {
  BoxInfo({
    required this.targetRenderBox,
    this.containerRenderBox,
    this.overlayOffset = Offset.zero,
  });

  factory BoxInfo.fromHitTestResults(
    Iterable<RenderBox> boxes, {
    Offset overlayOffset = Offset.zero,
  }) {
    RenderBox? targetRenderBox;
    RenderBox? containerRenderBox;

    for (final box in boxes) {
      targetRenderBox ??= box;

      if (targetRenderBox.size < box.size) {
        containerRenderBox = box;
        break;
      }
    }

    return BoxInfo(
      targetRenderBox: targetRenderBox!,
      containerRenderBox: containerRenderBox,
      overlayOffset: overlayOffset,
    );
  }

  final RenderBox targetRenderBox;
  final RenderBox? containerRenderBox;

  final Offset overlayOffset;

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
