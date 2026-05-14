import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class InspectorUtils {
  static RenderBox? _bypassAbsorbPointer(RenderProxyBox renderObject) {
    RenderBox _lastObject = renderObject;

    while (_lastObject is! RenderAbsorbPointer) {
      _lastObject = renderObject.child!;
    }

    return _lastObject.child;
  }

  static Iterable<RenderBox> findRenderObjectsAt(
    BuildContext context,
    Offset pointerOffset,
  ) sync* {
    final root = context.findRenderObject();
    if (root == null) return;

    yield* _collectAt(root, pointerOffset);
  }

  static Iterable<RenderBox> _collectAt(
    RenderObject renderObject,
    Offset globalOffset,
  ) sync* {
    if (renderObject is RenderBox && renderObject.hasSize) {
      final globalRect = MatrixUtils.transformRect(
        renderObject.getTransformTo(null),
        Offset.zero & renderObject.size,
      );

      // Skip non-visible render objects (e.g. empty bounds or invalid transforms).
      // Also prune subtrees whose global bounds do not contain the target point,
      // since their descendants cannot intersect it under normal non-overflowing
      // layouts.
      if (!globalRect.isFinite || globalRect.isEmpty) return;
      if (!globalRect.contains(globalOffset)) return;

      yield renderObject;
    }

    final children = <RenderObject>[];
    renderObject.visitChildren(children.add);

    // Reverse order for Stack like ordering
    for (final child in children.reversed) {
      yield* _collectAt(child, globalOffset);
    }
  }

  @Deprecated("Use findRenderObjectsAt instead")
  static Iterable<RenderBox> onTap(BuildContext context, Offset pointerOffset) {
    final renderObject = context.findRenderObject() as RenderProxyBox?;

    if (renderObject == null) return [];

    final renderObjectWithoutAbsorbPointer = _bypassAbsorbPointer(renderObject);

    if (renderObjectWithoutAbsorbPointer == null) return [];

    final hitTestResult = BoxHitTestResult();
    renderObjectWithoutAbsorbPointer.hitTest(
      hitTestResult,
      position: renderObjectWithoutAbsorbPointer.globalToLocal(pointerOffset),
    );

    return hitTestResult.path
        .where((v) => v.target is RenderBox)
        .map((v) => v.target)
        .cast<RenderBox>();
  }
}
