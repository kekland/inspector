import 'package:flutter/rendering.dart';

extension RenderBoxExtension on RenderBox {
  /// When a [RenderBox] is a child of a [RenderFittedBox], its size is scaled to fit the parent.
  Size get displaySize {
    if (parent is RenderFittedBox) {
      final fittedBox = parent as RenderFittedBox;

      // Compute the scale by comparing the size of the parent with that of the child
      final parentSize = fittedBox.size;
      final childSize = size;

      // The FittedBox applies a uniform scale, we can use width or height
      if (childSize.width > 0 && childSize.height > 0) {
        final scaleX = parentSize.width / childSize.width;
        final scaleY = parentSize.height / childSize.height;
        // BoxFit.contain by default
        final scale = scaleX < scaleY ? scaleX : scaleY;

        return Size(
          childSize.width * scale,
          childSize.height * scale,
        );
      }
    }
    return size;
  }
}
