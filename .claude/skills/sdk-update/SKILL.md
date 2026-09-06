---
name: sdk-update
description: Bring flutter_agent_lints up to date with a new Dart SDK minor.
disable-model-invocation: true
---

# SDK update

Run this when `environment: sdk` in `pubspec.yaml` has moved to a new Dart
minor and the installed SDK (`dart --version`) matches it. Every step ends on
a check; the work is done when all of them pass, not before.

Decisions follow the Principles section of README.md, in order: robustness,
one way to write it, token efficiency.

## 1. Decide every new rule

```bash
dart run tool/check_rules.dart
```

For every undecided rule it lists, add a line at the alphabetical position in
`lib/analysis_options.yaml` (stable rules) or `lib/experimental.yaml`
(experimental rules), as `true` or `false` with a one-line reason in the same
style as its neighbours. Read the rule's documentation at
`https://dart.dev/lints/<rule>` before deciding. A rule is `false` only for a
reason of a kind already in the file: it is the losing side of an
incompatible pair, it is redundant with a stricter setting, it demands work
that adds no correctness, or the language makes it moot.

Done when the command reports no undecided rules.

## 2. Retire what the SDK retired

```bash
dart analyze --fatal-infos
```

Remove any rule it reports as deprecated or removed. For an incompatible pair
it reports, set the side that contradicts the principles to `false`.

Done when the command reports no issues in the option files.

## 3. Pin the bundled analyzer

```bash
dart run .claude/skills/sdk-update/scripts/bundled_analyzer_version.dart
```

Set the `analyzer` dev dependency in `pubspec.yaml` to exactly the printed
version, then `dart pub get --no-example`.

## 4. Regenerate and verify

```bash
dart run tool/generate.dart
dart analyze --fatal-infos
dart test
dart run tool/check_rules.dart
dart run tool/generate.dart --check
```

Done when all five pass.

## 5. Version and changelog

Follow `.claude/skills/versioning/SKILL.md`.
