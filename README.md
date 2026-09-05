# flutter_agent_lints

Strict Dart and Flutter analysis options for codebases that are written mostly
by coding agents.

Every lint rule and analyzer diagnostic of the targeted Dart SDK is either
enabled as an **error** or explicitly disabled with a one-line reason. Nothing
is left at its default. The goal is to minimize the solution space: where the
language or the linter offers two ways to write something, exactly one is
allowed, and the analyzer enforces it instead of a reviewer.

## Install

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_agent_lints: ^1.0.0
```

```yaml
# analysis_options.yaml
include: package:flutter_agent_lints/analysis_options.yaml
```

The file works for Flutter apps and for pure Dart packages alike. Flutter
specific rules are inert when Flutter is not imported.

To opt into the rules the SDK still marks experimental:

```yaml
include: package:flutter_agent_lints/experimental.yaml
```

## Principles

In priority order:

1. **Robustness.** Anything that prevents a class of bugs is on: unawaited
   futures, bare catches, dynamic calls, unclosed sinks, `BuildContext` across
   async gaps.
2. **One way to write it.** Single quotes, package imports, final locals,
   expression bodies, sorted members. Style is decided in the file, not in
   review.
3. **Token efficiency.** Types and keywords are required only where they carry
   information the compiler cannot derive. Local variable types are omitted,
   closure parameter types are omitted, doc comments are not mandatory.

## What the file contains

[`lib/analysis_options.yaml`](lib/analysis_options.yaml) is the whole product
and is meant to be read. It has:

- Strict language modes: `strict-casts`, `strict-inference`, `strict-raw-types`.
- Formatter pinned to the defaults (`page_width: 80`,
  `trailing_commas: automate`) so they are never a project-level choice.
- Excludes for generated files (`*.g.dart`, `*.freezed.dart`, and friends).
- Every stable lint rule of the SDK, alphabetically, as `true` or `false` with
  a reason.
- A generated `analyzer.errors` block that promotes every enabled lint and
  every warning- or info-level analyzer diagnostic (including `todo`) to an
  error.

Rules that are off, and why, in short:

| Rule | Reason |
| --- | --- |
| `always_specify_types` and the `specify_nonobvious_*` family | Types are written only where inference fails. |
| `public_member_api_docs` | Forced doc comments produce filler that misleads. |
| `diagnostic_describe_all_properties` | Inspector boilerplate on every widget, not correctness. |
| `require_trailing_commas` | The formatter owns trailing commas. |
| `do_not_use_environment` | `--dart-define` via `String.fromEnvironment` is the standard Flutter path. |
| `prefer_double_quotes`, `prefer_relative_imports`, `unnecessary_final` | The losing side of a rule pair. |
| `avoid_final_parameters` | Dart 3.13 rejects `final` on parameters at the language level. |

The full list with rationale is in the file itself.

## Versioning

Any change to the effective rule set is a **major** version bump: a rule added,
removed, or changed in severity is a build break for a consumer. The
`environment: sdk` lower bound in `pubspec.yaml` is the SDK whose rule set the
file enumerates and moves with each major.

New Dart releases are tracked automatically. When a new stable SDK ships, a
pull request is opened that adds every new rule and diagnostic with a proposed
decision for review.

## Contributing

All changes go through pull requests. To propose a rule change, edit the rule's
line in `lib/analysis_options.yaml`, state the new reason in the comment, and
regenerate the errors block:

```bash
dart run tool/generate.dart
```

CI verifies that the file is complete against the SDK, that no incompatible or
deprecated rule is enabled, that the generated block is current, and that the
example app analyzes clean.

## License

MIT. See [LICENSE](LICENSE).
