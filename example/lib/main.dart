import 'package:flutter/material.dart';
import 'package:inspector/inspector.dart';

void main() {
  runApp(
    MaterialApp(
      home: const ExampleApp(),
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      builder: (context, child) => Inspector(
        isEnabled: true,
        child: child!,
      ),
    ),
  );
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({Key? key}) : super(key: key);

  @override
  State createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  Widget _buildListItem(int index) {
    return ListTile(
      title: Text('Item #$index'),
      subtitle: const Text('A subtitle'),
      leading: Container(
        width: 32.0,
        height: 32.0,
        decoration: BoxDecoration(
          color: Colors.purple,
          borderRadius: BorderRadius.circular(16.0),
        ),
        alignment: Alignment.center,
        child: Text(
          '$index',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.add),
        onPressed: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example'),
      ),
      body: ListView.builder(
        itemCount: 100,
        itemBuilder: (context, i) => _buildListItem(i),
      ),
    );
  }
}
