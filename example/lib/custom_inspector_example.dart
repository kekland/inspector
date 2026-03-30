import 'package:flutter/material.dart';
import 'package:inspector/inspector.dart';
import 'package:draggable_panel/draggable_panel.dart';

void main() {
  runApp(const CustomInspectorExample());
}

class CustomInspectorExample extends StatelessWidget {
  const CustomInspectorExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        return Inspector(
          child: child!,
          panelBuilder: (context, controller, child) {
            return ListenableBuilder(
              listenable: controller.modeNotifier,
              child: child,
              builder: (context, child) => DraggablePanel(
                items: [
                  DraggablePanelItem(
                    icon: Icons.format_shapes,
                    enableBadge: controller.modeNotifier.value ==
                        InspectorMode.inspector,
                    onTap: (context) {
                      controller.setMode(
                        controller.modeNotifier.value == InspectorMode.inspector
                            ? InspectorMode.none
                            : InspectorMode.inspector,
                      );
                    },
                  ),
                  DraggablePanelItem(
                    icon: Icons.colorize,
                    enableBadge: controller.modeNotifier.value ==
                        InspectorMode.colorPicker,
                    onTap: (context) {
                      controller.setMode(
                        controller.modeNotifier.value ==
                                InspectorMode.colorPicker
                            ? InspectorMode.none
                            : InspectorMode.colorPicker,
                        context: context,
                      );
                    },
                  ),
                  DraggablePanelItem(
                    icon: Icons.zoom_in,
                    enableBadge:
                        controller.modeNotifier.value == InspectorMode.zoom,
                    onTap: (context) {
                      controller.setMode(
                        controller.modeNotifier.value == InspectorMode.zoom
                            ? InspectorMode.none
                            : InspectorMode.zoom,
                      );
                    },
                  ),
                ],
                child: child,
              ),
            );
          },
        );
      },
      home: Scaffold(
        appBar: AppBar(title: const Text('Custom Inspector Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                color: Colors.red,
                child: const Center(child: Text('Red Box')),
              ),
              const SizedBox(height: 20),
              Container(
                width: 100,
                height: 100,
                color: Colors.blue,
                child: const Center(child: Text('Blue Box')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
