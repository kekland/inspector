import 'package:flutter/widgets.dart';

class InspectorUtils {
  /// Recursively visits children of a given [renderObject] and calls [callback]
  /// on each child until [callback] returns [true].
  static void _recursivelyVisitChildren(
    RenderObject renderObject,
    bool Function(RenderObject) callback,
  ) {
    renderObject.visitChildren((child) {
      if (callback(child)) return;

      _recursivelyVisitChildren(child, callback);
    });
  }

  static void onTap(BuildContext context, Offset offset) {
    print('\nonTap:');
    final renderObject = context.findRenderObject();
    _recursivelyVisitChildren(renderObject,);
  }
}
