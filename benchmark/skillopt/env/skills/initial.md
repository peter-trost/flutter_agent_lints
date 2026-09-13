# Strict Dart

Every lint and analyzer diagnostic is an error here, so code that would
merely warn elsewhere does not build for review.


## Verify

After writing the code, run:

```bash
dart fix --apply && dart format . && dart analyze
```

`dart fix --apply` first, not `dart analyze` alone: it mechanically resolves
most of what this ruleset flags, in one command rather than several
read-diagnostic-then-edit rounds.

`dart analyze` must print `No issues found!`.

## Not options

- **Never add `// ignore:` or `// ignore_for_file:`.** If a rule seems wrong
  for a case, say so in your final message rather than silencing it.
- **Never edit `analysis_options.yaml`** to make analysis pass.
- **TODO comments are errors.** Finish the work or describe what is missing
  in your message.
- **Never edit generated files** (`*.g.dart`, `*.freezed.dart` and friends)
  to satisfy a lint; they are already excluded.

<!-- reference: dart -->
# Dart rules

## Constructors omit the class name

Dart 3.13 declaring constructors: inside a class, the unnamed constructor is
spelled `new`, not the class name. `unnecessary_type_name_in_constructor`
makes the old spelling an error. Callers are unaffected: `Settings(...)`
still works.

```dart
class Settings {
  // not `const Settings({...})`
  const new({required this.username, this.fontSize = 14});

  // not `factory Settings.fromJson(...)`
  factory fromJson(Map<String, Object?> json) =>
      Settings(username: json['username']! as String);

  final String username;
  final int fontSize;
}
```

A named constructor keeps its own name (`Settings.empty()`); only the class
name in front of it goes away. The two forms above are the whole rule.

## Fields are initialized by the parameter, not in the body

`prefer_initializing_formals` wants `this.x`, and where the field is private
the parameter is written `this._x`. Writing `SearchModel({required
SearchFetcher fetcher}) : _fetcher = fetcher` is an error.

```dart
class SearchModel {
  new({
    required this._fetcher,
    this._debounce = const Duration(milliseconds: 300),
  });

  final Future<List<String>> Function(String) _fetcher;
  final Duration _debounce;
}
```

## Tests are analyzed too

Files under `test/` face the same rules, and in measured runs they were the
single largest source of fix-loop churn. Two rules do most of it:

- `avoid_dynamic_calls` and the strict inference modes reject an untyped
  fake or callback, so give every test double and closure parameter a type.
- `cascade_invocations` fires on consecutive calls to one object during
  setup, which is a common shape in tests.

```dart
class Recorder {
  final calls = <String>[];

  Future<List<String>> fetch(String query) async {
    calls.add(query);
    return [query];
  }
}
```

## Consecutive calls on one receiver are a cascade

`cascade_invocations` covers test files too, which is where it usually
fires:

```dart
class Cart {
  final _items = <String>[];

  void add(String item) => _items.add(item);
}

void build() {
  final cart = Cart()
    ..add('apple')
    ..add('pear');
}
```

## Equality requires @immutable

`avoid_equals_and_hash_code_on_mutable_classes` means a class with `==` and
`hashCode` must carry `@immutable`, which in turn requires every field to be
`final`. Import the annotation from a package the project declares:
`package:flutter/foundation.dart` in a Flutter app, `package:meta/meta.dart`
only where `meta` is a listed dependency, because
`depend_on_referenced_packages` rejects any other import. If the class cannot
be immutable, it should not define equality; compare the fields at the call
site instead.

## Handled by `dart fix --apply`

These fire often, and the command resolves every one:

| Rule | What it wants |
| --- | --- |
| `prefer_expression_function_bodies` | A body that is a single `return` becomes `=>` |
| `omit_obvious_property_types`, `omit_local_variable_types` | No annotation where the initializer already states the type. `final count = 0` and `var _results = <String>[]`, not `final int count = 0` or `List<String> _results = <String>[]`. A field with no initializer still needs its type, and so does one whose initializer is a bare `[]` or `{}` |
| `prefer_final_locals` | `final` on every local that is not reassigned |
| `always_put_required_named_parameters_first` | Required named parameters before optional ones |
| `sort_pub_dependencies` | Alphabetical dependencies in `pubspec.yaml` |
| `directives_ordering`, `always_use_package_imports` | Sorted imports, `package:` not relative, inside `lib/` |

## Not fixable by command

Each of these is a decision made while writing:

- **`avoid_catches_without_on_clauses`**: name the type you catch. To catch
  everything deliberately, `on Object catch (e)` says so explicitly.
- **`unawaited_futures`, `discarded_futures`**: every future is awaited or
  passed to `unawaited(...)` from `dart:async`. A dropped future loses its
  errors, which is why this is an error and not a style preference.
- **`avoid_dynamic_calls`, strict casts, strict inference, strict raw
  types**: no implicit `dynamic` anywhere. JSON decoding starts at
  `Object?` and every step down is an explicit check or cast, and generic
  types state their arguments (`List<String>`, never bare `List`).
- **`only_throw_errors`**: throw an `Exception` or `Error` subtype, so `on`
  clauses can catch it.
- **`prefer_asserts_with_message`**: every `assert` carries a message.
- **Doc comments are not required**, so do not add them to satisfy the
  analyzer. In one you do write, `comment_references` requires every
  `[Name]` to resolve in scope; plain text is safer than a bracket whose
  target is not imported.

<!-- reference: flutter -->
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
