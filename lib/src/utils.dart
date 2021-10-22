import 'package:flutter/gestures.dart';
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

  static Iterable<RenderBox> onTap(BuildContext context, Offset pointerOffset) {
    final renderObject = context.findRenderObject() as RenderBox?;

    if (renderObject == null) return [];

    final hitTestResult = BoxHitTestResult();
    renderObject.hitTest(
      hitTestResult,
      position: renderObject.globalToLocal(pointerOffset),
    );

    return hitTestResult.path
        .where((v) => v.target is RenderBox)
        .map((v) => v.target)
        .cast<RenderBox>();
  }
}
