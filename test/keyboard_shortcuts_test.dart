import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspector/inspector.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _buildApp({
  List<LogicalKeyboardKey>? inspectorShortcuts,
  List<LogicalKeyboardKey>? inspectAndCompareShortcuts,
  List<LogicalKeyboardKey>? colorPickerShortcuts,
  List<LogicalKeyboardKey>? zoomShortcuts,
}) {
  return MaterialApp(
    builder: (context, child) => Inspector(
      inspectorShortcuts: inspectorShortcuts ??
          const [
            LogicalKeyboardKey.alt,
            LogicalKeyboardKey.altLeft,
            LogicalKeyboardKey.altRight,
            LogicalKeyboardKey.meta,
            LogicalKeyboardKey.metaLeft,
            LogicalKeyboardKey.metaRight,
          ],
      inspectAndCompareShortcuts:
          inspectAndCompareShortcuts ?? const [LogicalKeyboardKey.keyY],
      colorPickerShortcuts: colorPickerShortcuts ??
          const [
            LogicalKeyboardKey.shift,
            LogicalKeyboardKey.shiftLeft,
            LogicalKeyboardKey.shiftRight,
          ],
      zoomShortcuts: zoomShortcuts ?? const [LogicalKeyboardKey.keyZ],
      child: child!,
    ),
    home: const Scaffold(body: SizedBox()),
  );
}

InspectorMode _mode(WidgetTester tester) => tester
    .state<InspectorState>(find.byType(Inspector))
    .controller
    .modeNotifier
    .value;

// Zoom and colorPicker modes trigger async GPU work (boundary.toImage /
// toByteData). These are platform-level callbacks that pumpAndSettle cannot
// drain on its own. Call this helper at the end of any test that activates
// those modes so the work completes while the widget is still mounted,
// preventing "ValueNotifier used after dispose" errors.
Future<void> _drainScreenshotCapture(WidgetTester tester) async {
  await tester.pump(); // fires addPostFrameCallback → starts _extractByteData
  await tester.runAsync(() async {}); // lets platform callbacks complete
  await tester.pump(); // process any pending frame work
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // We use LogicalKeyboardKey.control as the modifier throughout most tests.
  // It satisfies the hasModifier guard (present in _modifierKeys) but is NOT
  // in the default inspectorShortcuts list, so pressing it alone won't
  // accidentally activate inspector mode and pollute assertions.

  group('modifier guard — inspectAndCompare (keyY)', () {
    testWidgets(
      'given no modifier held, when keyY pressed, then mode stays none',
      (tester) async {
        // Given
        await tester.pumpWidget(_buildApp());

        // When
        await tester.sendKeyDownEvent(LogicalKeyboardKey.keyY);
        await tester.pump();

        // Then
        expect(_mode(tester), InspectorMode.none);

        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyY);
        await tester.pump();
      },
    );

    testWidgets(
      'given control held, when keyY pressed, then mode becomes inspectAndCompare',
      (tester) async {
        // Given
        await tester.pumpWidget(_buildApp());

        // When – mode changes synchronously via KeyboardHandler
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.keyY);

        // Then – check before pump; inspectAndCompare has no screenshot capture
        expect(_mode(tester), InspectorMode.inspectAndCompare);

        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyY);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pump();
      },
    );

    testWidgets(
      'given control released before keyY, when keyY released, then mode is no longer inspectAndCompare',
      (tester) async {
        // Given – activate inspectAndCompare
        await tester.pumpWidget(_buildApp());
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.keyY);
        expect(_mode(tester), InspectorMode.inspectAndCompare);

        // When – release modifier first, then the letter key
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyY);

        // Then – mode must not be stuck.
        // (_toggleMode special case: leaving inspectAndCompare → inspector.)
        expect(_mode(tester), isNot(InspectorMode.inspectAndCompare));

        await tester.pump();
      },
    );
  });

  group('modifier guard — zoom (keyZ)', () {
    testWidgets(
      'given no modifier held, when keyZ pressed, then mode stays none',
      (tester) async {
        // Given
        await tester.pumpWidget(_buildApp());

        // When
        await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
        await tester.pump();

        // Then
        expect(_mode(tester), InspectorMode.none);

        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
        await tester.pump();
      },
    );

    testWidgets(
      'given control held, when keyZ pressed, then mode becomes zoom',
      (tester) async {
        // Given
        await tester.pumpWidget(_buildApp());

        // When – mode changes synchronously
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);

        // Then – check before pump to avoid triggering screenshot work before assertion
        expect(_mode(tester), InspectorMode.zoom);

        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        // Drain async screenshot capture (boundary.toImage / toByteData)
        // before the widget is torn down.
        await _drainScreenshotCapture(tester);
      },
    );

    testWidgets(
      'given control released before keyZ, when keyZ released, then mode is no longer zoom',
      (tester) async {
        // Given – activate zoom
        await tester.pumpWidget(_buildApp());
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
        expect(_mode(tester), InspectorMode.zoom);

        // When – release modifier first, then letter key
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);

        // Then – mode must not be stuck at zoom
        expect(_mode(tester), isNot(InspectorMode.zoom));

        await _drainScreenshotCapture(tester);
      },
    );
  });

  group('modifier-only shortcuts are unaffected by the guard', () {
    testWidgets(
      'alt alone activates inspector mode',
      (tester) async {
        // Given
        await tester.pumpWidget(_buildApp());

        // When
        await tester.sendKeyDownEvent(LogicalKeyboardKey.alt);
        await tester.pump();

        // Then
        expect(_mode(tester), InspectorMode.inspector);

        await tester.sendKeyUpEvent(LogicalKeyboardKey.alt);
        await tester.pump();
        expect(_mode(tester), InspectorMode.none);
      },
    );

    testWidgets(
      'shift alone activates colorPicker mode',
      (tester) async {
        // Given
        await tester.pumpWidget(_buildApp());

        // When – mode changes synchronously
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);

        // Then
        expect(_mode(tester), InspectorMode.colorPicker);

        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);

        // Drain async screenshot capture before widget teardown
        await _drainScreenshotCapture(tester);
        expect(_mode(tester), InspectorMode.none);
      },
    );
  });

  group('Inspector.inspectAndCompareShortcuts customisation', () {
    testWidgets(
      'given custom key F1, control+keyY does not activate inspectAndCompare',
      (tester) async {
        // Given – F1 replaces default keyY
        await tester.pumpWidget(
          _buildApp(inspectAndCompareShortcuts: const [LogicalKeyboardKey.f1]),
        );

        // When – press the old default with a modifier
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.keyY);
        await tester.pump();

        // Then
        expect(_mode(tester), isNot(InspectorMode.inspectAndCompare));

        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyY);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pump();
      },
    );

    testWidgets(
      'given custom key F1, control+F1 activates inspectAndCompare',
      (tester) async {
        // Given
        await tester.pumpWidget(
          _buildApp(inspectAndCompareShortcuts: const [LogicalKeyboardKey.f1]),
        );

        // When
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.f1);

        // Then – check synchronously; inspectAndCompare has no screenshot
        expect(_mode(tester), InspectorMode.inspectAndCompare);

        await tester.sendKeyUpEvent(LogicalKeyboardKey.f1);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pump();
      },
    );
  });

  group('Inspector.inspectorShortcuts customisation', () {
    testWidgets(
      'given custom key F2, alt does not activate inspector mode',
      (tester) async {
        // Given
        await tester.pumpWidget(
          _buildApp(inspectorShortcuts: const [LogicalKeyboardKey.f2]),
        );

        // When
        await tester.sendKeyDownEvent(LogicalKeyboardKey.alt);
        await tester.pump();

        // Then
        expect(_mode(tester), InspectorMode.none);

        await tester.sendKeyUpEvent(LogicalKeyboardKey.alt);
        await tester.pump();
      },
    );

    testWidgets(
      'given custom key F2, F2 activates and deactivates inspector mode',
      (tester) async {
        // Given
        await tester.pumpWidget(
          _buildApp(inspectorShortcuts: const [LogicalKeyboardKey.f2]),
        );

        // When
        await tester.sendKeyDownEvent(LogicalKeyboardKey.f2);
        await tester.pump();
        expect(_mode(tester), InspectorMode.inspector);

        await tester.sendKeyUpEvent(LogicalKeyboardKey.f2);
        await tester.pump();

        // Then
        expect(_mode(tester), InspectorMode.none);
      },
    );
  });

  group('Inspector.zoomShortcuts customisation', () {
    testWidgets(
      'given custom key F3, control+keyZ does not activate zoom',
      (tester) async {
        // Given – F3 replaces default keyZ
        await tester.pumpWidget(
          _buildApp(zoomShortcuts: const [LogicalKeyboardKey.f3]),
        );

        // When – press old default with a modifier
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
        await tester.pump();

        // Then
        expect(_mode(tester), isNot(InspectorMode.zoom));

        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pump();
      },
    );

    testWidgets(
      'given custom key F3, control+F3 activates zoom',
      (tester) async {
        // Given
        await tester.pumpWidget(
          _buildApp(zoomShortcuts: const [LogicalKeyboardKey.f3]),
        );

        // When – mode changes synchronously
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.f3);

        // Then – check before pump; drain screenshot capture afterwards
        expect(_mode(tester), InspectorMode.zoom);

        await tester.sendKeyUpEvent(LogicalKeyboardKey.f3);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await _drainScreenshotCapture(tester);
      },
    );
  });

  group('Inspector.colorPickerShortcuts customisation', () {
    testWidgets(
      'given custom key F4, default shift does not activate colorPicker',
      (tester) async {
        // Given
        await tester.pumpWidget(
          _buildApp(colorPickerShortcuts: const [LogicalKeyboardKey.f4]),
        );

        // When
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        await tester.pump();

        // Then
        expect(_mode(tester), InspectorMode.none);

        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
        await tester.pump();
      },
    );

    testWidgets(
      'given custom key F4, F4 activates and deactivates colorPicker',
      (tester) async {
        // Given
        await tester.pumpWidget(
          _buildApp(colorPickerShortcuts: const [LogicalKeyboardKey.f4]),
        );

        // When – mode changes synchronously
        await tester.sendKeyDownEvent(LogicalKeyboardKey.f4);

        // Then
        expect(_mode(tester), InspectorMode.colorPicker);

        await tester.sendKeyUpEvent(LogicalKeyboardKey.f4);
        await _drainScreenshotCapture(tester);
        expect(_mode(tester), InspectorMode.none);
      },
    );
  });
}
