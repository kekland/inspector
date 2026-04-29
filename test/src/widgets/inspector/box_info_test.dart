import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspector/src/widgets/inspector/box_info.dart';

const _parentKey = ValueKey('parent');
const _childKey = ValueKey('child');
const _largeKey = ValueKey('large');
const _smallKey = ValueKey('small');
const _foregroundKey = ValueKey('foreground');
const _backgroundKey = ValueKey('background');

void main() {
  testWidgets(
    'given a single box, '
    'when calling fromHitTestResults, '
    'then that box becomes the target',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(key: _parentKey, width: 100, height: 100),
        ),
      );

      final box = tester.renderObject(find.byKey(_parentKey)) as RenderBox;
      final info = BoxInfo.fromHitTestResults([box]);

      expect(info.targetRenderBox, same(box));
    },
  );

  testWidgets(
    'given nested boxes with different sizes, '
    'when calling fromHitTestResults, '
    'then the smallest child is the target',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: SizedBox(
              key: _parentKey,
              width: 200,
              height: 200,
              child: Center(
                child: SizedBox(key: _childKey, width: 50, height: 50),
              ),
            ),
          ),
        ),
      );

      final parent = tester.renderObject(find.byKey(_parentKey)) as RenderBox;
      final child = tester.renderObject(find.byKey(_childKey)) as RenderBox;

      // Simulate the parent-first order produced by _collectAt
      final info = BoxInfo.fromHitTestResults([parent, child]);

      expect(info.targetRenderBox, same(child));
    },
  );

  testWidgets(
    'given sibling boxes with different areas, '
    'when calling fromHitTestResults, '
    'then the smallest area wins regardless of list order',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Stack(
            children: [
              SizedBox(key: _largeKey, width: 100, height: 100),
              SizedBox(key: _smallKey, width: 30, height: 30),
            ],
          ),
        ),
      );

      final large = tester.renderObject(find.byKey(_largeKey)) as RenderBox;
      final small = tester.renderObject(find.byKey(_smallKey)) as RenderBox;

      // large first
      expect(BoxInfo.fromHitTestResults([large, small]).targetRenderBox,
          same(small));
      // small first – result must be the same
      expect(BoxInfo.fromHitTestResults([small, large]).targetRenderBox,
          same(small));
    },
  );

  testWidgets(
    'given boxes with equal area, '
    'when calling fromHitTestResults, '
    'then the deepest box in the tree wins',
    (tester) async {
      // Both boxes are 100×100, but _childKey is nested inside _parentKey.
      // _collectAt yields parent first → child comes last in the list.
      // The child is a descendant of the parent, so it wins (more specific).
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: SizedBox(
              key: _parentKey,
              width: 100,
              height: 100,
              child: SizedBox(key: _childKey, width: 100, height: 100),
            ),
          ),
        ),
      );

      final parent = tester.renderObject(find.byKey(_parentKey)) as RenderBox;
      final child = tester.renderObject(find.byKey(_childKey)) as RenderBox;

      final info = BoxInfo.fromHitTestResults([parent, child]);

      expect(info.targetRenderBox, same(child));
    },
  );

  testWidgets(
    'given Stack siblings with equal area, '
    'when calling fromHitTestResults, '
    'then the foreground sibling (first in list) wins over the background one',
    (tester) async {
      // _collectAt reverses children before recursing, so for a Stack with
      // [background, foreground] the foreground is emitted first.
      // When two siblings share the same area, neither is a descendant of the
      // other → the first element (foreground) must be kept as the target.
      await tester.pumpWidget(
        const MaterialApp(
          home: Stack(
            children: [
              SizedBox(key: _backgroundKey, width: 100, height: 100),
              SizedBox(key: _foregroundKey, width: 100, height: 100),
            ],
          ),
        ),
      );

      final foreground =
          tester.renderObject(find.byKey(_foregroundKey)) as RenderBox;
      final background =
          tester.renderObject(find.byKey(_backgroundKey)) as RenderBox;

      // Simulate the order produced by _collectAt (foreground first)
      final info = BoxInfo.fromHitTestResults([foreground, background]);

      expect(info.targetRenderBox, same(foreground),
          reason:
              'foreground sibling must win over background when areas are equal');
    },
  );

  testWidgets(
    'given Stack siblings with equal area listed background-first, '
    'when calling fromHitTestResults, '
    'then the first element in the list wins (list order is respected for siblings)',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Stack(
            children: [
              SizedBox(key: _backgroundKey, width: 100, height: 100),
              SizedBox(key: _foregroundKey, width: 100, height: 100),
            ],
          ),
        ),
      );

      final foreground =
          tester.renderObject(find.byKey(_foregroundKey)) as RenderBox;
      final background =
          tester.renderObject(find.byKey(_backgroundKey)) as RenderBox;

      // If caller passes background first, background wins – the contract is
      // "first sibling wins", so the caller (_collectAt) is responsible for
      // ordering (foreground first via children.reversed).
      final info = BoxInfo.fromHitTestResults([background, foreground]);

      expect(info.targetRenderBox, same(background),
          reason: 'first sibling in list wins when areas are equal');
    },
  );

  testWidgets(
    'given multiple boxes, '
    'when calling fromHitTestResults, '
    'then hitTestPath preserves all boxes in original order',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: SizedBox(
              key: _parentKey,
              width: 200,
              height: 200,
              child: Center(
                child: SizedBox(key: _childKey, width: 50, height: 50),
              ),
            ),
          ),
        ),
      );

      final parent = tester.renderObject(find.byKey(_parentKey)) as RenderBox;
      final child = tester.renderObject(find.byKey(_childKey)) as RenderBox;
      final boxes = [parent, child];

      final info = BoxInfo.fromHitTestResults(boxes);

      expect(info.hitTestPath, equals(boxes));
      expect(info.hitTestPath.length, 2);
    },
  );

  testWidgets(
    'given a box with an overlayOffset, '
    'when accessing targetRectShifted, '
    'then it returns targetRect shifted by the negative overlayOffset',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(key: _parentKey, width: 100, height: 100),
        ),
      );

      final box = tester.renderObject(find.byKey(_parentKey)) as RenderBox;
      const offset = Offset(10, 20);

      final info = BoxInfo.fromHitTestResults([box], overlayOffset: offset);

      expect(info.targetRectShifted, equals(info.targetRect.shift(-offset)));
    },
  );

  testWidgets(
    'given nested boxes, '
    'when calling fromHitTestResults with findContainer=false, '
    'then containerRenderBox is null',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: SizedBox(
              key: _parentKey,
              width: 200,
              height: 200,
              child: Center(
                child: SizedBox(key: _childKey, width: 50, height: 50),
              ),
            ),
          ),
        ),
      );

      final parent = tester.renderObject(find.byKey(_parentKey)) as RenderBox;
      final child = tester.renderObject(find.byKey(_childKey)) as RenderBox;

      final info = BoxInfo.fromHitTestResults(
        [parent, child],
        findContainer: false, // default
      );

      expect(info.containerRenderBox, isNull);
    },
  );

  testWidgets(
    'given nested boxes with an ancestor larger than the target, '
    'when calling fromHitTestResults with findContainer=true, '
    'then containerRenderBox is set to the nearest larger ancestor',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: SizedBox(
              key: _parentKey,
              width: 200,
              height: 200,
              child: Center(
                child: SizedBox(key: _childKey, width: 50, height: 50),
              ),
            ),
          ),
        ),
      );

      final parent = tester.renderObject(find.byKey(_parentKey)) as RenderBox;
      final child = tester.renderObject(find.byKey(_childKey)) as RenderBox;

      final info = BoxInfo.fromHitTestResults(
        [parent, child],
        findContainer: true,
      );

      expect(info.targetRenderBox, same(child));
      expect(info.containerRenderBox, same(parent));
    },
  );

  testWidgets(
    'given sibling boxes where the large box is not an ancestor of the small box, '
    'when calling fromHitTestResults with findContainer=true, '
    'then containerRenderBox stays null',
    (tester) async {
      // Large and small boxes are siblings in a Stack: large is NOT an ancestor of small.
      await tester.pumpWidget(
        const MaterialApp(
          home: Stack(
            children: [
              SizedBox(key: _largeKey, width: 200, height: 200),
              SizedBox(key: _smallKey, width: 30, height: 30),
            ],
          ),
        ),
      );

      final large = tester.renderObject(find.byKey(_largeKey)) as RenderBox;
      final small = tester.renderObject(find.byKey(_smallKey)) as RenderBox;

      final info = BoxInfo.fromHitTestResults(
        [large, small],
        findContainer: true,
      );

      expect(info.targetRenderBox, same(small));
      // large is a sibling, not an ancestor → cannot be a container
      expect(info.containerRenderBox, isNull);
    },
  );

  testWidgets(
    'given boxes with multiple ancestors of different sizes, '
    'when calling fromHitTestResults with findContainer=true, '
    'then containerRenderBox is the smallest ancestor larger than the target',
    (tester) async {
      const _grandParentKey = ValueKey('grandparent');

      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: SizedBox(
              key: _grandParentKey,
              width: 300,
              height: 300,
              child: Center(
                child: SizedBox(
                  key: _parentKey,
                  width: 150,
                  height: 150,
                  child: Center(
                    child: SizedBox(key: _childKey, width: 50, height: 50),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final grandParent =
          tester.renderObject(find.byKey(_grandParentKey)) as RenderBox;
      final parent = tester.renderObject(find.byKey(_parentKey)) as RenderBox;
      final child = tester.renderObject(find.byKey(_childKey)) as RenderBox;

      final info = BoxInfo.fromHitTestResults(
        [grandParent, parent, child],
        findContainer: true,
      );

      expect(info.targetRenderBox, same(child));
      // parent (150×150) is smaller than grandParent (300×300) but still larger
      // than child (50×50) → parent should be picked as the nearest container.
      expect(info.containerRenderBox, same(parent));
    },
  );
}
