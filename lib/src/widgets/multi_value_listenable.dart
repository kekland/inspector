import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MultiValueListenableBuilder extends StatefulWidget {
  const MultiValueListenableBuilder({
    Key? key,
    required this.valueListenables,
    required this.builder,
  }) : super(key: key);

  final List<ValueListenable> valueListenables;
  final WidgetBuilder builder;

  @override
  _MultiValueListenableBuilderState createState() =>
      _MultiValueListenableBuilderState();
}

class _MultiValueListenableBuilderState
    extends State<MultiValueListenableBuilder> {
  @override
  void initState() {
    super.initState();
    _registerListeners();
  }

  void _onUpdated() {
    setState(() {});
  }

  void _registerListeners() {
    for (final listenable in widget.valueListenables) {
      listenable.addListener(_onUpdated);
    }
  }

  void _deregisterListeners() {
    for (final listenable in widget.valueListenables) {
      listenable.removeListener(_onUpdated);
    }
  }

  @override
  void dispose() {
    _deregisterListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}
