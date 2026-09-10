# Flutter rules

Read [dart.md](dart.md) first; everything there applies to widget code too.
These rules add to it.

## Widgets

- **`use_key_in_widget_constructors`**: every public widget constructor takes
  `{super.key}`. Note where it sits: `super.key` is optional, and
  `always_put_required_named_parameters_first` puts required parameters
  ahead of it, so the familiar `{super.key, required this.x}` ordering is an
  error here. Combined with the declaring-constructor rule from dart.md:

  ```dart
  class CountdownTimer extends StatefulWidget {
    const new({required this.controller, super.key, this.onFinished});

    final CountdownController controller;
    final VoidCallback? onFinished;
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
  // Inside a State, the context is State.context, so guard on the State.
  await work();
  if (!mounted) return;
  Navigator.of(context).pop();

  // A context held as a variable or parameter guards on itself.
  Future<void> f(BuildContext context) async {
    await work();
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }
  ```
- Equality on a widget's state or controller still needs `@immutable`; where
  the class is a `ChangeNotifier` it is mutable by definition, so do not
  define `==` on it.

## Platform and color

- **`avoid_web_libraries_in_flutter`**: no `dart:html` or friends; they break
  every non-web build.
- **`use_full_hex_values_for_flutter_colors`**: write the alpha byte.
  `Color(0xFFFFFF)` is fully transparent, which is almost never what was
  meant; `Color(0xFFFFFFFF)` is white.
