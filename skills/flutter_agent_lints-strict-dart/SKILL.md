---
name: flutter_agent_lints-strict-dart
description: Read before editing Dart code.
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

`lines_longer_than_80_chars` is on: 80 columns is the maximum per line.

## Not options

- **Never add `// ignore:` or `// ignore_for_file:`.** If a rule seems wrong
  for a case, say so in your final message rather than silencing it.
- **TODO comments are errors.** Finish the work or describe what is missing
  in your message.
