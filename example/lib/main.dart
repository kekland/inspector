import 'package:flutter/material.dart';
import 'package:inspector/inspector.dart';

void main() {
  runApp(
    MaterialApp(
      home: ExampleApp(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      builder: (context, child) => Inspector(child: child!),
    ),
  );
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({Key? key}) : super(key: key);

  @override
  _ExampleAppState createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  Widget _buildListItem(int index) {
    return ListTile(
      title: Text('Item #$index'),
      subtitle: Text('A subtitle'),
      leading: Container(
        width: 32.0,
        height: 32.0,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '$index',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Example'),
      ),
      body: ListView.builder(
        itemCount: 100,
        itemBuilder: (context, i) => _buildListItem(i),
      ),
    );
  }
}
