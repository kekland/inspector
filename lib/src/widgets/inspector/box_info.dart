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

  /// Calculate original padding by comparing positions in local coordinates
  EdgeInsets _calculateOriginalPadding() {
    if (containerRenderBox == null) return EdgeInsets.zero;

    // Get the target's position relative to the container
    final targetOffset = targetRenderBox.localToGlobal(Offset.zero);
    final containerOffset = containerRenderBox!.localToGlobal(Offset.zero);

    // Calculate scale factor from the transformation
    final scaledTargetSize = targetRect.size;
    final originalTargetSize = targetRenderBox.size;
    final scale = originalTargetSize.width > 0
        ? scaledTargetSize.width / originalTargetSize.width
        : 1.0;

    // Calculate padding in original coordinates
    final left = (targetOffset.dx - containerOffset.dx) / scale;
    final top = (targetOffset.dy - containerOffset.dy) / scale;
    final right =
        containerRenderBox!.size.width - originalTargetSize.width - left;
    final bottom =
        containerRenderBox!.size.height - originalTargetSize.height - top;

    // Snap sub-pixel floating-point noise to zero.
    double snap(double v) => v.abs() < 0.5 ? 0.0 : v;
    return EdgeInsets.fromLTRB(
        snap(left), snap(top), snap(right), snap(bottom));
  }

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

  /// Describes the original (logical) padding without zoom transformation.
  String describeOriginalPadding() {
    final padding = _calculateOriginalPadding();

    final _left = padding.left.toStringAsFixed(1);
    final _top = padding.top.toStringAsFixed(1);
    final _right = padding.right.toStringAsFixed(1);
    final _bottom = padding.bottom.toStringAsFixed(1);

    return 'L:$_left  T:$_top  R:$_right  B:$_bottom';
  }

  /// True when the detected container is a flex layout (Row/Column).
  bool get isContainerFlex => containerRenderBox is RenderFlex;

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

  /// The nearest [RenderDecoratedBox] with [BoxDecoration] relevant to the
  /// selected target. Checks the target directly, then the hit-test path,
  /// then the target's direct child — in that priority order.
  RenderDecoratedBox? get decoratedBoxForDisplay =>
      _findSelectedDecoratedBox() ??
      _findNearestDecoratedBoxFromHitTestPath() ??
      _findChildDecoratedBoxFromTarget();

  RenderDecoratedBox? _findSelectedDecoratedBox() =>
      targetRenderBox is RenderDecoratedBox
          ? targetRenderBox as RenderDecoratedBox
          : null;

  RenderDecoratedBox? _findNearestDecoratedBoxFromHitTestPath() {
    for (final box in hitTestPath) {
      if (box.size != targetRect.size) return null;
      if (box is RenderDecoratedBox) return box;
    }
    return null;
  }

  RenderDecoratedBox? _findChildDecoratedBoxFromTarget() {
    if (targetRenderBox is RenderProxyBoxMixin) {
      final child = (targetRenderBox as RenderProxyBoxMixin).child;
      if (child != null &&
          child.size == targetRenderBox.size &&
          child is RenderDecoratedBox) {
        return child;
      }
    }
    return null;
  }

  /// The fill color of a [ColoredBox] that is or wraps the target, if any.
  ///
  /// [_RenderColoredBox] is a private Flutter class — dynamic dispatch is used
  /// because there is no public type to cast to.
  Color? get coloredBoxColor =>
      _tryColoredBoxColor(targetRenderBox) ??
      (targetRenderBox is RenderProxyBoxMixin
          ? _tryColoredBoxColorFromProxy(targetRenderBox as RenderProxyBoxMixin)
          : null);

  Color? _tryColoredBoxColorFromProxy(RenderProxyBoxMixin proxy) {
    final child = proxy.child;
    if (child is RenderBox && child.size == targetRenderBox.size) {
      return _tryColoredBoxColor(child);
    }
    return null;
  }

  Color? _tryColoredBoxColor(RenderBox box) {
    if (!box.runtimeType.toString().contains('ColoredBox')) return null;
    try {
      return (box as dynamic).color as Color;
    } catch (_) {
      return null;
    }
  }
}

Rect? getRectFromRenderBox(RenderBox renderBox) {
  if (!renderBox.attached) return null;

  final topLeft = renderBox.localToGlobal(Offset.zero);
  final bottomRight = renderBox.localToGlobal(
    Offset(renderBox.size.width, renderBox.size.height),
  );

  return Rect.fromPoints(topLeft, bottomRight);
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
