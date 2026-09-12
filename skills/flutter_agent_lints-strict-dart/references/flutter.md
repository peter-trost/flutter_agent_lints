# Flutter rules

Everything in the Dart reference applies to widget code too; these rules add
to it.

## Widgets

- **`use_key_in_widget_constructors`**: every public widget constructor takes
  `{super.key}`. Note where it sits: `super.key` is optional, and
  `always_put_required_named_parameters_first` puts required parameters
  ahead of it, so the familiar `{super.key, required this.x}` ordering is an
  error here, combined with the declaring-constructor spelling:

  ```dart
  class CountdownTimer extends StatefulWidget {
    const new({required this.controller, super.key});

    final Listenable controller;

    @override
    State<CountdownTimer> createState() => _CountdownTimerState();
  }

  class _CountdownTimerState extends State<CountdownTimer> {
    @override
    Widget build(BuildContext context) => const Text('00:00');
  }
  ```

- **`prefer_const_constructors`, `prefer_const_constructors_in_immutables`**:
  const wherever the arguments allow it. A widget class whose fields are all
  final gets a const constructor.
- **`sort_child_properties_last`**: `child` and `children` come after every
  other argument, so the tree reads top to bottom.
- **`avoid_unnecessary_containers`**: a `Container` with a single argument is
  a more specific widget (`Padding`, `Align`, `ColoredBox`, `SizedBox`).
- **`sized_box_for_whitespace`**: fixed-size gaps are `SizedBox`, not a
  `Container` with width and height.
- **`no_logic_in_create_state`**: `createState` returns the state and does
  nothing else; Flutter calls it in ways that break otherwise.

## Async and BuildContext

- **`use_build_context_synchronously`**: a `BuildContext` used after an
  `await` may belong to a disposed widget. The guard has to match where the
  context came from, and the rule rejects the wrong one as "guarded by an
  unrelated 'mounted' check":

  ```dart
  class _ExampleState extends State<StatefulWidget> {
    // The context here is State.context, so the guard is on the State.
    Future<void> save(Future<void> Function() work) async {
      await work();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    }

    @override
    Widget build(BuildContext context) => const SizedBox.shrink();
  }

  // A context held as a parameter or variable guards on itself.
  Future<void> saveWith(
    BuildContext context,
    Future<void> Function() work,
  ) async {
    await work();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop();
  }
  ```
- Equality on a widget's state or controller still needs `@immutable`; a
  `ChangeNotifier` is mutable by definition, so do not define `==` on it.

## Platform and color

- **`avoid_web_libraries_in_flutter`**: no `dart:html` or friends; they break
  every non-web build.
- **`use_full_hex_values_for_flutter_colors`**: write the alpha byte.
  `Color(0xFFFFFF)` is fully transparent, which is almost never what was
  meant; `Color(0xFFFFFFFF)` is white.
