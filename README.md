# flutter_agent_lints

Strict Dart and Flutter analysis options for codebases that are written mostly
by coding agents.

Every lint rule and analyzer diagnostic of the targeted Dart SDK is either
enabled as an **error** or explicitly disabled with a one-line reason. Nothing
is left at its default. The goal is to minimize the solution space: where the
language or the linter offers two ways to write something, exactly one is
allowed, and the analyzer enforces it instead of a reviewer.

## Install

```bash
dart pub add dev:flutter_agent_lints
```

```yaml
# analysis_options.yaml
include: package:flutter_agent_lints/analysis_options.yaml
```

The file works for Flutter apps and for pure Dart packages alike. Flutter
specific rules are inert when Flutter is not imported.

To opt into the rules the SDK still marks experimental (they can be renamed or
removed between SDK releases):

```yaml
include: package:flutter_agent_lints/experimental.yaml
```

## The agent skill

The package ships a skill that front-loads the rules agents otherwise
learn from the analyzer one fix loop at a time. Install it into the
project that depends on this package:

```bash
dart run skills@ get
```

That is the [`skills`](https://pub.dev/packages/skills) CLI, which finds
skills bundled in your dependency tree and installs them for Claude Code,
Codex, Cursor, Copilot and others. Rerun it after upgrading so the skill
matches the ruleset you have. It is a skill rather than a block in
`AGENTS.md` so a repository that is only partly Dart does not pay for it in
sessions that never touch a `.dart` file; the Flutter rules sit in their
own reference file for the same reason.

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
- Everything that is on is an **error**, including every warning- and
  info-level analyzer diagnostic (`todo` too). An agent can ignore a warning;
  it cannot ignore an error.

The reason a rule is on or off sits next to the rule in the file. That is the
single source of truth; nothing here repeats it.

## Does it help?

Measured, not assumed. `benchmark/` gives headless Claude Code three
tasks with hidden tests under three arms: the Flutter default
`flutter_lints`, this package alone, and this package with its skill.
Then it starts from what each arm wrote and asks for one more feature,
which is where a stricter, more uniform codebase should pay back what it
cost to write. Every number below comes from those runs, and anyone with
a Flutter SDK and a Claude Code login can regenerate them:

```bash
cd benchmark && dart pub get
dart run bin/agents.dart            # 3 tasks x 3 arms x 5 runs, from an empty file
dart run bin/agents.dart --change   # 3 tasks x 2 arms x 5 runs, one feature on top
dart run bin/agents_report.dart     # rewrites the two tables below
```

How to read them: **All tests passed** is correctness. **Turns** and
**Tokens** are what the run cost. **Lines** is how much code came out.
**Diagnostics read** is how often the analyzer sent the agent back.
**Changed lines** is the size of the diff for the same feature.

<!-- agents -->
45 runs of opus over 3 tasks (countdown, search_model, settings_parser). Hidden tests run after the agent stops; diagnostics read are analyzer diagnostics in output the agent saw during the run.

| Option set | Runs | All tests passed | Turns | Tokens | Lines | Diagnostics read |
| --- | --- | --- | --- | --- | --- | --- |
| flutter_lints | 15 | 15 of 15 | 10.1 | 421k | 168 | 0.8 |
| flutter_agent_lints | 15 | 14 of 15 | 23.2 | 1094k | 146 | 10.8 |
| flutter_agent_lints+skill | 15 | 15 of 15 | 17.5 | 712k | 140 | 3.9 |
<!-- /agents -->

<!-- changes -->
30 runs of opus over 3 tasks (countdown, search_model, settings_parser). Each run starts from the code a recorded run of the arm after the @ produced and asks for one feature on top of it; changed lines are lines added or removed in the solution file. Hidden tests run after the agent stops; diagnostics read are analyzer diagnostics in output the agent saw during the run.

| Option set | Runs | All tests passed | Turns | Tokens | Lines | Diagnostics read | Changed lines |
| --- | --- | --- | --- | --- | --- | --- | --- |
| flutter_lints@flutter_lints | 15 | 15 of 15 | 11.3 | 440k | 191 | 0.0 | 25.5 |
| flutter_agent_lints+skill@flutter_agent_lints+skill | 15 | 15 of 15 | 13.7 | 478k | 155 | 0.3 | 17.6 |
<!-- /changes -->

What the runs say, at five per cell: the package without the skill is a
tax with no return. With the skill, writing from an empty file still
costs 1.7x the turns of `flutter_lints`, because every rule fires once on
the way; changing existing code costs about two turns more, which is the
skill load, and the diff comes out about 30% smaller on code about 20%
shorter. Correctness is the same in every arm. See
[benchmark/README.md](benchmark/README.md) for what the harness does and
does not control for.

## Contributing

To propose a rule change, edit the rule's line in `lib/analysis_options.yaml`,
state the new reason in the comment, and regenerate `lib/errors.yaml`:

```bash
dart run tool/generate.dart
```
