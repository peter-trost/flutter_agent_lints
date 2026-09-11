---
name: flutter_agent_lints-strict-dart
description: Writes Dart and Flutter code under a strict analysis ruleset where every lint and analyzer diagnostic is an error rather than a warning. Covers declaring constructors, initializing formals, cascades, immutable equality, strict type inference, widget keys, and BuildContext across async gaps. Use before writing or editing any Dart file in a project with strict analysis options, and when a Dart analyzer run fails on rules such as unnecessary_type_name_in_constructor, prefer_initializing_formals, cascade_invocations, avoid_equals_and_hash_code_on_mutable_classes, omit_obvious_property_types, unawaited_futures, discarded_futures, or avoid_catches_without_on_clauses. Not relevant to non-Dart code.
---

# Strict Dart

Every lint and analyzer diagnostic is an error here, so code that would
merely warn elsewhere does not build for review.

## Read the reference for what you are writing

- **[references/dart.md](references/dart.md)** — always. Constructors,
  initializing formals, cascades, equality, the strict type modes, and the
  rules `dart fix` handles for you.
- **[references/flutter.md](references/flutter.md)** — only when the file
  imports Flutter. Widget constructors and keys, const, child-last, and
  `BuildContext` after an await. Those rules cannot fire in a pure Dart
  package.

## Verify

After writing the code, run:

```bash
dart fix --apply && dart format . && dart analyze
```

`dart fix --apply` first, not `dart analyze` alone: it mechanically resolves
most of what this ruleset flags, in one command rather than several
read-diagnostic-then-edit rounds.

`dart analyze` must print `No issues found!`.

`lines_longer_than_80_chars` is on: no line, including a single-expression
`=>` body or a chained call, may exceed 80 columns. Break it the way
`dart format` would:

```dart
import 'dart:async';

class EventBus {
  final _controller = StreamController<Object>.broadcast();

  Stream<T> on<T>() =>
      _controller.stream.where((event) => event is T).cast<T>();

  Future<void> dispose() => _controller.close();
}
```

## Not options

- **Never add `// ignore:` or `// ignore_for_file:`.** If a rule seems wrong
  for a case, say so in your final message rather than silencing it.
- **Never edit `analysis_options.yaml`** to make analysis pass.
- **TODO comments are errors.** Finish the work or describe what is missing
  in your message.
- **Never edit generated files** (`*.g.dart`, `*.freezed.dart` and friends)
  to satisfy a lint; they are already excluded.
