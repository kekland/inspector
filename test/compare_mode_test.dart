import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspector/inspector.dart';

const _containerAKey = ValueKey('containerA');
const _containerBKey = ValueKey('containerB');

Widget _buildBody() {
  return MaterialApp(
    builder: (context, child) => Inspector(child: child!),
    home: Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            key: _containerAKey,
            width: 100.0,
            height: 100.0,
            color: Colors.blue,
          ),
          Container(
            key: _containerBKey,
            width: 100.0,
            height: 100.0,
            color: Colors.red,
          ),
        ],
      ),
    ),
  );
}

InspectorController _getController(WidgetTester tester) =>
    tester.state<InspectorState>(find.byType(Inspector)).controller;

Offset _centerOf(WidgetTester tester, Key key) {
  final renderBox = tester.renderObject(find.byKey(key)) as RenderBox;
  return (renderBox.localToGlobal(Offset.zero) & renderBox.size).center;
}

Future<void> _enterInspectorAndSelectA(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.format_shapes));
  await tester.pump();

  await tester.tapAt(_centerOf(tester, _containerAKey));
  await tester.pump();
}

void main() {
  group('Compare button in widget info panel', () {
    testWidgets('shows after selecting a widget', (tester) async {
      // Given
      await tester.pumpWidget(_buildBody());
      await _enterInspectorAndSelectA(tester);

      // Then
      expect(find.byIcon(Icons.compare), findsOneWidget);
    });

    testWidgets('does not show without a selected widget', (tester) async {
      // Given — inspector on but no widget tapped
      await tester.pumpWidget(_buildBody());
      await tester.tap(find.byIcon(Icons.format_shapes));
      await tester.pump();

      // Then — info panel not visible, no Compare button
      expect(find.byIcon(Icons.compare), findsNothing);
    });

    testWidgets('enters compareSelect mode on tap', (tester) async {
      // Given
      await tester.pumpWidget(_buildBody());
      await _enterInspectorAndSelectA(tester);

      // When
      await tester.tap(find.byIcon(Icons.compare));
      await tester.pump();

      // Then
      final controller = _getController(tester);
      expect(controller.modeNotifier.value, InspectorMode.compareSelect);
      expect(find.byIcon(Icons.compare), findsOneWidget);
    });

    testWidgets('exits compareSelect on Cancel tap', (tester) async {
      // Given
      await tester.pumpWidget(_buildBody());
      await _enterInspectorAndSelectA(tester);
      await tester.tap(find.byIcon(Icons.compare));
      await tester.pump();

      // When
      await tester.tap(find.byIcon(Icons.compare));
      await tester.pump();

      // Then
      final controller = _getController(tester);
      expect(controller.modeNotifier.value, InspectorMode.inspector);
      expect(controller.comparedRenderBoxNotifier.value, isNull);
      expect(find.byIcon(Icons.compare), findsOneWidget);
    });
  });

  group('Compare mode flow', () {
    testWidgets('tap second widget fixes both', (tester) async {
      // Given
      await tester.pumpWidget(_buildBody());
      await _enterInspectorAndSelectA(tester);
      final controller = _getController(tester);
      final firstRenderBox =
          controller.currentRenderBoxNotifier.value!.targetRenderBox;

      await tester.tap(find.byIcon(Icons.compare));
      await tester.pump();

      // When
      await tester.tapAt(_centerOf(tester, _containerBKey));
      await tester.pump();

      // Then — both are fixed, mode is back to inspector
      expect(controller.modeNotifier.value, InspectorMode.inspector);
      expect(
        controller.currentRenderBoxNotifier.value?.targetRenderBox,
        firstRenderBox,
      );
      expect(controller.comparedRenderBoxNotifier.value, isNotNull);
    });

    testWidgets('tapping the same widget is rejected', (tester) async {
      // Given
      await tester.pumpWidget(_buildBody());
      await _enterInspectorAndSelectA(tester);
      await tester.tap(find.byIcon(Icons.compare));
      await tester.pump();

      // When — tap the same container A again
      await tester.tapAt(_centerOf(tester, _containerAKey));
      await tester.pump();

      // Then — compared stays null, mode returns to inspector
      final controller = _getController(tester);
      expect(controller.modeNotifier.value, InspectorMode.inspector);
      expect(controller.comparedRenderBoxNotifier.value, isNull);
    });

    testWidgets('exit inspector clears compare state', (tester) async {
      // Given — confirm a compare first
      await tester.pumpWidget(_buildBody());
      await _enterInspectorAndSelectA(tester);
      await tester.tap(find.byIcon(Icons.compare));
      await tester.pump();
      await tester.tapAt(_centerOf(tester, _containerBKey));
      await tester.pump();

      final controller = _getController(tester);
      expect(controller.comparedRenderBoxNotifier.value, isNotNull);

      // When — turn off inspector via the FAB
      await tester.tap(
        find.ancestor(
          of: find.byIcon(Icons.format_shapes),
          matching: find.byType(FloatingActionButton),
        ),
      );
      await tester.pump();

      // Then
      expect(controller.modeNotifier.value, InspectorMode.none);
      expect(controller.currentRenderBoxNotifier.value, isNull);
      expect(controller.comparedRenderBoxNotifier.value, isNull);
    });
  });

  group('Y key compare toggle', () {
    testWidgets('Y key enters compareSelect after widget is selected',
        (tester) async {
      // Given
      await tester.pumpWidget(_buildBody());
      await _enterInspectorAndSelectA(tester);

      // When
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyY);
      await tester.pump();

      // Then
      final controller = _getController(tester);
      expect(controller.modeNotifier.value, InspectorMode.compareSelect);
    });

    testWidgets('Y key does nothing when no widget selected', (tester) async {
      // Given
      await tester.pumpWidget(_buildBody());
      await tester.tap(find.byIcon(Icons.format_shapes));
      await tester.pump();

      // When
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyY);
      await tester.pump();

      // Then — stays in inspector, no compareSelect
      final controller = _getController(tester);
      expect(controller.modeNotifier.value, InspectorMode.inspector);
    });

    testWidgets('Y key toggles off compareSelect', (tester) async {
      // Given
      await tester.pumpWidget(_buildBody());
      await _enterInspectorAndSelectA(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyY);
      await tester.pump();

      expect(
        _getController(tester).modeNotifier.value,
        InspectorMode.compareSelect,
      );

      // When
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyY);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyY);
      await tester.pump();

      // Then
      final controller = _getController(tester);
      expect(controller.modeNotifier.value, InspectorMode.inspector);
      expect(controller.comparedRenderBoxNotifier.value, isNull);
    });

    testWidgets('Y key up does not exit compareSelect (no hold behaviour)',
        (tester) async {
      // Given
      await tester.pumpWidget(_buildBody());
      await _enterInspectorAndSelectA(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyY);
      await tester.pump();

      // When — release key (old hold behaviour would have exited here)
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyY);
      await tester.pump();

      // Then — still in compareSelect
      final controller = _getController(tester);
      expect(controller.modeNotifier.value, InspectorMode.compareSelect);
    });
  });
}
