import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class InspectorUtils {
  static RenderViewport? findAncestorViewport(RenderObject box) {
    if (box is RenderViewport) return box;

    if (box.parent != null && box.parent is RenderObject) {
      return findAncestorViewport(box.parent! as RenderObject);
    }

    return null;
  }

  static RenderBox? _bypassAbsorbPointer(RenderProxyBox renderObject) {
    RenderBox _lastObject = renderObject;

    while (_lastObject is! RenderAbsorbPointer) {
      _lastObject = renderObject.child!;
    }

    return _lastObject.child;
  }

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
