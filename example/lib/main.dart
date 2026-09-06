import 'package:flutter/material.dart';

void main() => runApp(const CounterApp());

class CounterApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) =>
      const MaterialApp(title: 'Counter', home: CounterPage());
}

class CounterPage extends StatefulWidget {
  const new({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  var _count = 0;

  void _increment() => setState(() => _count++);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Counter')),
    body: Center(
      child: Text('$_count', style: Theme.of(context).textTheme.displayMedium),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _increment,
      tooltip: 'Increment',
      child: const Icon(Icons.add),
    ),
  );
}
