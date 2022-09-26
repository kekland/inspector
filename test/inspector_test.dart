import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspector/inspector.dart';

// class _ColorPickerTestPainter extends CustomPainter {
//   static Color localPositionToColor({
//     required Offset offset,
//     required Size size,
//   }) {
//     return Color.lerp(Colors.blue, Colors.red,
//         (offset.dx + offset.dy) / (size.width + size.height))!;
//   }

//   @override
//   void paint(Canvas canvas, Size size) {
//     for (var x = 0.0; x < size.width; x++) {
//       for (var y = 0.0; y < size.height; y++) {
//         final position = Offset(x, y);

//         canvas.drawRect(
//           Rect.fromLTRB(x, y, x + 1, y + 1),
//           Paint()..color = localPositionToColor(offset: position, size: size),
//         );
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

const _containerKey = ValueKey('container');
Widget _buildBody() {
  return MaterialApp(
    builder: (context, child) => Inspector(child: child!),
    home: Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(
        width: 200.0,
        height: 400.0,
        child: Stack(
          children: [
            Center(
              child: Container(
                key: _containerKey,
                width: 100.0,
                height: 100.0,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// const _painterKey = ValueKey('container');
// Widget _buildColorPickerTestBody() {
//   return MaterialApp(
//     builder: (context, child) => Inspector(child: child!),
//     home: Scaffold(
//       backgroundColor: Colors.black,
//       body: SizedBox(
//         width: 200.0,
//         height: 200.0,
//         child: CustomPaint(
//           key: _painterKey,
//           painter: _ColorPickerTestPainter(),
//         ),
//       ),
//     ),
//   );
// }

void main() {
  group('Inspector', () {
    testWidgets('panel shows up properly', (tester) async {
      await tester.pumpWidget(_buildBody());

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.byIcon(Icons.format_shapes), findsOneWidget);
      expect(find.byIcon(Icons.colorize), findsOneWidget);
    });

    testWidgets('panel can be collapsed', (tester) async {
      await tester.pumpWidget(_buildBody());

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.byIcon(Icons.format_shapes), findsOneWidget);
      expect(find.byIcon(Icons.colorize), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.format_shapes), findsNothing);
      expect(find.byIcon(Icons.colorize), findsNothing);
    });

    testWidgets('panel can be reopened', (tester) async {
      await tester.pumpWidget(_buildBody());
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.format_shapes), findsNothing);
      expect(find.byIcon(Icons.colorize), findsNothing);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.byIcon(Icons.format_shapes), findsOneWidget);
      expect(find.byIcon(Icons.colorize), findsOneWidget);
    });

    // testWidgets('open panel golden test', (tester) async {
    //   await tester.pumpWidget(_buildBody());

    //   await expectLater(
    //     find.byType(InspectorPanel),
    //     matchesGoldenFile('goldens/inspector_panel_open.png'),
    //   );
    // });

    // testWidgets('closed panel golden test', (tester) async {
    //   await tester.pumpWidget(_buildBody());
    //   await tester.tap(find.byIcon(Icons.chevron_right));
    //   await tester.pump();

    //   await expectLater(
    //     find.byType(InspectorPanel),
    //     matchesGoldenFile('goldens/inspector_panel_closed.png'),
    //   );
    // });
  });

  group('Widget inspector', () {
    testWidgets('can be toggled', (tester) async {
      await tester.pumpWidget(_buildBody());

      final finder = find.ancestor(
        of: find.byIcon(Icons.format_shapes),
        matching: find.byType(FloatingActionButton),
      );

      FloatingActionButton getButton() =>
          tester.widget(finder) as FloatingActionButton;

      expect(getButton().backgroundColor, Colors.white);
      expect(getButton().foregroundColor, Colors.black54);

      await tester.tap(find.byIcon(Icons.format_shapes));
      await tester.pump();

      expect(getButton().backgroundColor, Colors.blue);
      expect(getButton().foregroundColor, Colors.white);

      await tester.tap(find.byIcon(Icons.format_shapes));
      await tester.pump();

      expect(getButton().backgroundColor, Colors.white);
      expect(getButton().foregroundColor, Colors.black54);
    });

    testWidgets('can be toggled via keyboard shortcut', (tester) async {
      await tester.pumpWidget(_buildBody());

      final finder = find.ancestor(
        of: find.byIcon(Icons.format_shapes),
        matching: find.byType(FloatingActionButton),
      );

      FloatingActionButton getButton() =>
          tester.widget(finder) as FloatingActionButton;

      expect(getButton().backgroundColor, Colors.white);
      expect(getButton().foregroundColor, Colors.black54);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.alt);
      await tester.pump();

      expect(getButton().backgroundColor, Colors.blue);
      expect(getButton().foregroundColor, Colors.white);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.alt);
      await tester.pump();

      expect(getButton().backgroundColor, Colors.white);
      expect(getButton().foregroundColor, Colors.black54);
    });

    testWidgets('can hit-test a Container', (tester) async {
      await tester.pumpWidget(_buildBody());
      await tester.tap(find.byIcon(Icons.format_shapes));
      await tester.pump();

      final container =
          tester.renderObject(find.byKey(_containerKey)) as RenderBox;

      final position =
          (container.localToGlobal(Offset.zero) & container.size).center;

      await tester.tapAt(position);
      await tester.pump();

      expect(find.textContaining('RenderDecoratedBox'), findsOneWidget);
      expect(find.text('100.0 × 100.0'), findsWidgets);
      expect(find.text('50.0, 150.0, 50.0, 150.0'), findsOneWidget);
    });

    // testWidgets('hit-test result golden test', (tester) async {
    //   await tester.pumpWidget(_buildBody());
    //   await tester.tap(find.byIcon(Icons.format_shapes));
    //   await tester.pump();

    //   final container =
    //       tester.renderObject(find.byKey(_containerKey)) as RenderBox;

    //   final position =
    //       (container.localToGlobal(Offset.zero) & container.size).center;

    //   await tester.tapAt(position);
    //   await tester.pump();

    //   await expectLater(
    //     find.byType(BoxInfoPanelWidget),
    //     matchesGoldenFile('./goldens/box_info_panel_widget.png'),
    //   );
    // });
  });

  // group('Color picker', () {
  //   testWidgets('can be toggled', (tester) async {
  //     await tester.pumpWidget(_buildColorPickerTestBody());

  //     final finder = find.ancestor(
  //       of: find.byIcon(Icons.colorize),
  //       matching: find.byType(FloatingActionButton),
  //     );

  //     FloatingActionButton getButton() =>
  //         tester.widget(finder) as FloatingActionButton;

  //     expect(getButton().backgroundColor, Colors.white);
  //     expect(getButton().foregroundColor, Colors.black54);

  //     await tester.tap(find.byIcon(Icons.colorize));
  //     await tester.pumpAndSettle();

  //     expect(getButton().backgroundColor, Colors.blue);
  //     expect(getButton().foregroundColor, Colors.white);

  //     await tester.tap(find.byIcon(Icons.colorize));
  //     await tester.pumpAndSettle();

  //     expect(getButton().backgroundColor, Colors.white);
  //     expect(getButton().foregroundColor, Colors.black54);
  //   });

  //   test('colorToHexString returns right colors', () {
  //     final colors = {
  //       'aaaaaa': const Color(0xFFAAAAAA),
  //       'bbbbbb': const Color(0xFFBBBBBB),
  //       'cccccc': const Color(0xFFCCCCCC),
  //       'dddddd': const Color(0xFFDDDDDD),
  //     };

  //     for (final colorKey in colors.keys) {
  //       final color = colors[colorKey];
  //       expect(colorToHexString(color!), equals(colorKey));
  //     }
  //   });

  //   testWidgets('gets the right colors', (tester) async {
  //     await tester.pumpWidget(_buildColorPickerTestBody());
  //     await tester.tap(find.byIcon(Icons.colorize));

  //     await tester.pumpAndSettle(
  //       const Duration(milliseconds: 100),
  //       EnginePhase.build,
  //     );

  //     await expectLater(
  //       find.byType(InspectorPanel),
  //       matchesGoldenFile('a.png'),
  //     );

  //     // Not the cleanest way to do this, but whatever :P
  //     await tester.sendEventToBinding(
  //       const PointerDownEvent(position: Offset(1.0, 1.0)),
  //     );
  //     await tester.pump();

  //     await tester.sendEventToBinding(
  //       const PointerMoveEvent(
  //         delta: Offset(49.0, 49.0),
  //       ),
  //     );
  //     await tester.pump();

  //     await expectLater(
  //       find.byType(InspectorPanel),
  //       matchesGoldenFile('b.png'),
  //     );

  //     // var previousPosition = Offset.zero;
  //     // for (var x = 0.0; x < 200; x += 10) {
  //     //   for (var y = 0.0; y < 200; y += 10) {
  //     //     final position = Offset(x, y);
  //     //     final expectedColor = _ColorPickerTestPainter.localPositionToColor(
  //     //       offset: position,
  //     //       size: const Size(200.0, 200.0),
  //     //     );

  //     //     await tester.sendEventToBinding(PointerMoveEvent(
  //     //       delta: position - previousPosition,
  //     //     ));

  //     //     previousPosition = position;

  //     //     await tester.pump();

  //     //     final colorHex = colorToHexString(expectedColor);
  //     //     expect(find.text(colorHex), findsOneWidget);
  //     //   }
  //     // }
  //   });
  // });
}
