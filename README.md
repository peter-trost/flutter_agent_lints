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

The claim is testable. `benchmark/agents` gives headless Claude Code the
same three tasks under `flutter_lints` and under this package, several
times each, and measures hidden-test results, turns, what the strict
options still flag afterwards, and how alike the solutions to one task
turn out. See [benchmark/README.md](benchmark/README.md) for the method
and its limits.

<!-- agents -->
30 runs of opus over 3 tasks (countdown, search_model, settings_parser). Hidden tests are run after the agent stops; strict issues are diagnostics of the result under the full flutter_agent_lints options, whatever the run used; consistency is the mean pairwise token similarity of the solutions to one task.

| Option set | Runs | Hidden tests passed | All tests passed | Turns | Time | Strict issues left | Ignores added |
| --- | --- | --- | --- | --- | --- | --- | --- |
| flutter_agent_lints | 15 | 99.3% | 14 of 15 | 23.2 | 4.2 min | 0.0 | 0 |
| flutter_lints | 15 | 100.0% | 15 of 15 | 10.1 | 1.8 min | 9.7 | 0 |

| Task | Option set | Consistency | Lines | Tests passed |
| --- | --- | --- | --- | --- |
| countdown | flutter_agent_lints | 0.66 | 159.4 | 100.0% |
| countdown | flutter_lints | 0.77 | 178.8 | 100.0% |
| search_model | flutter_agent_lints | 0.68 | 112.8 | 97.5% |
| search_model | flutter_lints | 0.75 | 126.2 | 100.0% |
| settings_parser | flutter_agent_lints | 0.65 | 167.0 | 100.0% |
| settings_parser | flutter_lints | 0.81 | 199.4 | 100.0% |

Diagnostics the agents ran into most under flutter_agent_lints (occurrences in analyzer output they read):

| Rule | Occurrences |
| --- | --- |
| unnecessary_type_name_in_constructor | 24 |
| cascade_invocations | 17 |
| sort_pub_dependencies | 17 |
| omit_obvious_property_types | 16 |
| prefer_initializing_formals | 11 |
| argument_type_not_assignable | 10 |
| avoid_unused_constructor_parameters | 10 |
| extra_positional_arguments | 10 |
| extraneous_modifier | 9 |
| undefined_identifier | 8 |

Diagnostics the agents ran into most under flutter_lints (occurrences in analyzer output they read):

| Rule | Occurrences |
| --- | --- |
| prefer_initializing_formals | 10 |
| type_init_formals | 2 |
<!-- /agents -->

Those runs start from an empty file, so they measure the price of writing
under a strict set and cannot see the payoff it promises: code that is
cheaper to change later. For that, `benchmark/agents` also seeds a run with
the `lib/` an earlier run produced, asks for one feature on top of it under
the options that code was written with, and hands the agent the base task's
hidden tests as the project's own. Read the turns and the changed lines
together: a smaller diff for the same feature is what uniform code should
buy, and the turns are what producing it costs.

<!-- changes -->
15 runs of opus over 3 tasks (countdown, search_model, settings_parser). Each run is seeded with the code a recorded run of the arm after the @ produced, and asked for a change to it; changed lines are lines added or removed in the solution file. Hidden tests are run after the agent stops; strict issues are diagnostics of the result under the full flutter_agent_lints options, whatever the run used; consistency is the mean pairwise token similarity of the solutions to one task.

| Option set | Runs | Hidden tests passed | All tests passed | Turns | Time | Strict issues left | Ignores added | Changed lines |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| flutter_lints@flutter_lints | 15 | 100.0% | 15 of 15 | 11.3 | 1.2 min | 10.5 | 0 | 25.5 |

| Task | Option set | Consistency | Lines | Tests passed |
| --- | --- | --- | --- | --- |
| countdown | flutter_lints@flutter_lints | 0.76 | 200.8 | 100.0% |
| search_model | flutter_lints@flutter_lints | 0.73 | 142.0 | 100.0% |
| settings_parser | flutter_lints@flutter_lints | 0.78 | 228.8 | 100.0% |
<!-- /changes -->

## Contributing

To propose a rule change, edit the rule's line in `lib/analysis_options.yaml`,
state the new reason in the comment, and regenerate `lib/errors.yaml`:

```bash
dart run tool/generate.dart
```
