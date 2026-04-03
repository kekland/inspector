import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspector/src/widgets/inspector/compare_distances.dart';

void main() {
  group('computeCompareDistances — horizontal gap', () {
    test('from is left of to', () {
      // Given: from=(0,0,100,50), to=(150,0,250,50) → gap = 50
      final result = computeCompareDistances(
        const Rect.fromLTWH(0, 0, 100, 50),
        const Rect.fromLTWH(150, 0, 100, 50),
      );

      expect(result.length, 1);
      expect(result[0].side, CompareSide.right);
      expect(result[0].value, closeTo(50.0, 0.01));
      expect(result[0].isHorizontal, true);
      expect(result[0].icon, Icons.arrow_forward);
      expect(result[0].startOffset.dx, closeTo(100.0, 0.01));
      expect(result[0].endOffset.dx, closeTo(150.0, 0.01));
    });

    test('from is right of to', () {
      // Given: gap = 50 in the other direction
      final result = computeCompareDistances(
        const Rect.fromLTWH(150, 0, 100, 50),
        const Rect.fromLTWH(0, 0, 100, 50),
      );

      expect(result.length, 1);
      expect(result[0].side, CompareSide.left);
      expect(result[0].value, closeTo(50.0, 0.01));
      expect(result[0].icon, Icons.arrow_back);
    });
  });

  group('computeCompareDistances — vertical gap', () {
    test('from is above to', () {
      // Given: from=(0,0,100,50), to=(0,100,100,50) → gap = 50
      final result = computeCompareDistances(
        const Rect.fromLTWH(0, 0, 100, 50),
        const Rect.fromLTWH(0, 100, 100, 50),
      );

      expect(result.length, 1);
      expect(result[0].side, CompareSide.bottom);
      expect(result[0].value, closeTo(50.0, 0.01));
      expect(result[0].isHorizontal, false);
      expect(result[0].icon, Icons.arrow_downward);
      expect(result[0].startOffset.dy, closeTo(50.0, 0.01));
      expect(result[0].endOffset.dy, closeTo(100.0, 0.01));
    });

    test('from is below to', () {
      final result = computeCompareDistances(
        const Rect.fromLTWH(0, 100, 100, 50),
        const Rect.fromLTWH(0, 0, 100, 50),
      );

      expect(result.length, 1);
      expect(result[0].side, CompareSide.top);
      expect(result[0].value, closeTo(50.0, 0.01));
      expect(result[0].icon, Icons.arrow_upward);
    });
  });

  group('computeCompareDistances — diagonal', () {
    test('both H and V gap → two distances', () {
      // Given: diagonal placement
      final result = computeCompareDistances(
        const Rect.fromLTWH(0, 0, 100, 50),
        const Rect.fromLTWH(150, 100, 100, 50),
      );

      expect(result.length, 2);
      expect(result.where((d) => d.isHorizontal).length, 1);
      expect(result.where((d) => !d.isHorizontal).length, 1);

      final h = result.firstWhere((d) => d.isHorizontal);
      final v = result.firstWhere((d) => !d.isHorizontal);
      expect(h.value, closeTo(50.0, 0.01));
      expect(v.value, closeTo(50.0, 0.01));
    });
  });

  group('computeCompareDistances — overlap', () {
    test('to inside from → 4 LTRB distances', () {
      // Given: from=(0,0,100,100), to=(10,10,80,80) — to is fully inside from
      final result = computeCompareDistances(
        const Rect.fromLTWH(0, 0, 100, 100),
        const Rect.fromLTWH(10, 10, 80, 80), // right=90, bottom=90
      );

      expect(result.length, 4);
      expect(result.any((d) => d.side == CompareSide.left), true);
      expect(result.any((d) => d.side == CompareSide.top), true);
      expect(result.any((d) => d.side == CompareSide.right), true);
      expect(result.any((d) => d.side == CompareSide.bottom), true);

      for (final d in result) {
        expect(d.value, closeTo(10.0, 0.01));
      }
    });

    test('partial overlap — aligned edges produce zero distances (filtered)',
        () {
      // Given: same top/bottom edges, different left/right
      final result = computeCompareDistances(
        const Rect.fromLTWH(0, 0, 100, 100),
        const Rect.fromLTWH(10, 0, 80, 100), // top=0, bottom=100 same
      );

      // top and bottom should be 0 → filtered; left=10, right=10
      expect(result.length, 2);
      expect(result.any((d) => d.side == CompareSide.top), false);
      expect(result.any((d) => d.side == CompareSide.bottom), false);
    });
  });

  group('computeCompareDistances — scale', () {
    test('scale=2 halves logical values', () {
      // Given: screen gap = 100, scale = 2 → logical = 50
      final result = computeCompareDistances(
        const Rect.fromLTWH(0, 0, 100, 50),
        const Rect.fromLTWH(200, 0, 100, 50),
        scale: 2.0,
      );

      expect(result.length, 1);
      expect(result[0].value, closeTo(50.0, 0.01));
    });

    test('scale=1 is default', () {
      final resultDefault = computeCompareDistances(
        const Rect.fromLTWH(0, 0, 100, 50),
        const Rect.fromLTWH(160, 0, 100, 50),
      );
      final resultExplicit = computeCompareDistances(
        const Rect.fromLTWH(0, 0, 100, 50),
        const Rect.fromLTWH(160, 0, 100, 50),
        scale: 1.0,
      );

      expect(resultDefault[0].value, equals(resultExplicit[0].value));
    });
  });

  group('computeCompareDistances — filtering', () {
    test('distance below 0.5 is ignored', () {
      // Given: H gap = 0.3 → below threshold
      final result = computeCompareDistances(
        const Rect.fromLTWH(0, 0, 100, 50),
        const Rect.fromLTWH(100.3, 0, 100, 50),
      );

      expect(result.isEmpty, true);
    });

    test('touching edges (gap = 0) are ignored', () {
      // Given: from.right == to.left → gap = 0
      final result = computeCompareDistances(
        const Rect.fromLTWH(0, 0, 100, 50),
        const Rect.fromLTWH(100, 0, 100, 50),
      );

      expect(result.isEmpty, true);
    });

    test('overlap diff below 0.5 is ignored', () {
      // Given: left diff = 0.1 between overlapping boxes
      final result = computeCompareDistances(
        const Rect.fromLTWH(0, 0, 100, 100),
        const Rect.fromLTWH(0.1, 0, 99.9, 100),
      );

      expect(result.isEmpty, true);
    });
  });
}
