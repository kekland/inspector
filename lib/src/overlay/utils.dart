import 'package:flutter/widgets.dart';

class BoxInfo {
  final Rect rect;
  final Rect? outerRect;

  BoxInfo({
    required this.rect,
    this.outerRect,
  });
}

double calculateBoxPosition({
  required Rect rect,
  required double height,
}) {
  final padding = 8.0;
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
