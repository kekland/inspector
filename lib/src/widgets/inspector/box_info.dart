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

    /// Best-match strategy combining two criteria:
    ///   1. Smallest area  → most visually precise box under the pointer.
    ///   2. Deepest in tree as tiebreaker for equal-area boxes:
    ///      - If [box] is a descendant of [best] (parent-child), prefer [box]
    ///        (more specific child wins over its wrapper).
    ///      - If they are siblings (e.g. two Stack children of same size),
    ///        prefer [best], which arrived first because [_collectAt] reverses
    ///        children → foreground (topmost Z-order) is emitted before
    ///        background, so keeping [best] preserves the correct Stack order.
    RenderBox targetRenderBox = boxes.reduce((best, box) {
      final bestArea = best.size.width * best.size.height;
      final boxArea = box.size.width * box.size.height;
      if (boxArea < bestArea) return box;
      if (boxArea == bestArea && box.isDescendantOf(best)) return box;
      return best;
    });
    RenderBox? containerRenderBox;

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

    // Use targetRect.topLeft (center-based, rotation-invariant) instead of
    // localToGlobal(Offset.zero) which rotates every frame inside Transform.rotate.
    final targetTopLeft = targetRect.topLeft;
    final containerTopLeft = containerRect!.topLeft;

    // Calculate scale factor from the transformation
    final scaledTargetSize = targetRect.size;
    final originalTargetSize = targetRenderBox.size;
    final scale = originalTargetSize.width > 0
        ? scaledTargetSize.width / originalTargetSize.width
        : 1.0;

    // Calculate padding in original coordinates
    final left = (targetTopLeft.dx - containerTopLeft.dx) / scale;
    final top = (targetTopLeft.dy - containerTopLeft.dy) / scale;
    final right =
        containerRenderBox!.size.width - originalTargetSize.width - left;
    final bottom =
        containerRenderBox!.size.height - originalTargetSize.height - top;

    return EdgeInsets.fromLTRB(left, top, right, bottom);
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
  if (!renderBox.attached) return null;

  // Anchor on the center instead of corners: the center is invariant under
  // Transform.rotate, keeping the overlay rect stable during animations.
  // Half-dimensions are measured as center-to-edge distances so that
  // Transform.scale is still reflected in the visual rect size.
  final center = renderBox.localToGlobal(renderBox.size.center(Offset.zero));

  final rightCenter = renderBox.localToGlobal(
    Offset(renderBox.size.width, renderBox.size.height / 2),
  );
  final bottomCenter = renderBox.localToGlobal(
    Offset(renderBox.size.width / 2, renderBox.size.height),
  );

  final halfWidth = (rightCenter - center).distance;
  final halfHeight = (bottomCenter - center).distance;

  return Rect.fromCenter(
    center: center,
    width: halfWidth * 2,
    height: halfHeight * 2,
  );
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
