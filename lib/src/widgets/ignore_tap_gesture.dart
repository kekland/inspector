import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

// This widget is used to block tap events from reaching the underlying widgets.
// It allow others gestures (e.g. hover events) to be processed without blocking them.
class IgnoreTapGesture extends StatelessWidget {
  const IgnoreTapGesture({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: {
        BlockingGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<BlockingGestureRecognizer>(
          () => BlockingGestureRecognizer(),
          (BlockingGestureRecognizer instance) {},
        ),
      },
    );
  }
}

// This gesture recognizer is used to block all pointer events from reaching the underlying widgets.
// It blocks single pointers completely, but allows multiple pointers (e.g. for hover events) to be processed.
class BlockingGestureRecognizer extends OneSequenceGestureRecognizer {
  final Set<int> _pointers = {};

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _pointers.add(event.pointer);

    if (_pointers.length > 1) {
      // Allow multiple pointers (for hover, etc.)
      resolve(GestureDisposition.rejected);
      return;
    }

    // Start tracking this pointer to capture ALL events (down, move, up, cancel)
    startTrackingPointer(event.pointer, event.transform);
    // Immediately win the gesture arena to prevent underlying widgets from receiving any events
    resolve(GestureDisposition.accepted);
  }

  @override
  void handleEvent(PointerEvent event) {
    // Continue tracking all events (move, up, cancel) to keep blocking
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _pointers.remove(event.pointer);
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void acceptGesture(int pointer) {
    // We've won the arena - consume all events for this pointer
  }

  @override
  void rejectGesture(int pointer) {
    // We've lost the arena (shouldn't happen since we win immediately)
    _pointers.remove(pointer);
    stopTrackingPointer(pointer);
  }

  @override
  String get debugDescription => 'BlockingGestureRecognizer';

  @override
  void dispose() {
    _pointers.clear();
    super.dispose();
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    // Called when we stop tracking the last pointer
    // In our case, we've already resolved the arena in addAllowedPointer,
    // so we don't need to do anything here
  }
}
