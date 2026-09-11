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
