import 'package:flutter/material.dart';
import 'package:inspect/inspect.dart';

void main() {
  runApp(
    Inspector(
      child: MaterialApp(
        home: ExampleApp(),
      ),
    ),
  );
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({Key? key}) : super(key: key);

  @override
  _ExampleAppState createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Example'),
      ),
      body: Center(
        child: Container(
          width: 100.0,
          height: 100.0,
          color: Colors.green,
        ),
      ),
    );
  }
}
