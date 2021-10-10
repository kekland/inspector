import 'package:flutter/widgets.dart';
import 'package:inspect/src/inspect.dart';

class Inspector extends StatelessWidget {
  const Inspector({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerUp: (v) {
        InspectorUtils.onTap(context, v.position);
      },
      child: child,
    );
  }
}
