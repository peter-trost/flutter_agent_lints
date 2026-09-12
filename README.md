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

Because every diagnostic is an error, an agent that writes first and reads
diagnostics afterwards pays for it in fix-loop iterations. The package ships a
skill that front-loads the rules those iterations are spent on. Install it into
the project that depends on this package:

```bash
dart run skills@ get
```

That is the [`skills`](https://pub.dev/packages/skills) CLI, which finds skills
bundled in your dependency tree and installs them for Claude Code, Codex,
Cursor, Copilot and others. Rerun it after upgrading so the skill matches the
ruleset you have.

It is a skill rather than a block in `AGENTS.md` on purpose. In a repository
that is only partly Dart, an always-loaded instruction spends context on every
session that never touches a `.dart` file; a skill loads only when its
description matches the work. The Flutter rules sit in their own reference file
for the same reason, so a pure Dart package never pulls them in.

Measured on the tasks in `benchmark/agents`, with the skill installed the
way `dart run skills@ get` installs it, an agent changing code written
under this ruleset reads a handful of diagnostics per fifteen runs instead
of dozens, spends about two turns more than under `flutter_lints` (the
skill load and its references), uses 8% more tokens, and produces a diff
about 30% smaller for the same feature. Every hidden test passes in both.
The wording was tuned with Microsoft's SkillOpt against single-shot tasks
scored by the analyzer; see `benchmark/skillopt`. The change table below
has the comparison; the rows without `registered` in their name were run
with the skill hidden from the agent, which is why they cost more.

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

The claim that fewer allowed forms make agent code more robust is testable
in part. The `benchmark/` directory mines bug-fix commits from open-source
Flutter apps and asks, for each option set, whether the lines a human later
fixed carried a diagnostic before the fix. See
[benchmark/README.md](benchmark/README.md) for the method and its limits.

Read the per-rule lift rather than the totals. A rule about robustness
shows a lift well above one because the fix removed what it flagged. A
rule about form sits near or below one because a fix rarely rewrites a
line for its style; that half of the package is about consistency, which
this measurement cannot see.

<!-- benchmark -->
Corpus: 158 bug-fix commits from localsend, saber, wger. Fixed lines are the lines each fix deleted or replaced; a line is flagged when it carried a diagnostic that the fix made go away. Lift compares that with how often any line of the same files carries a diagnostic.

| Option set | Commits flagged | Fixed lines flagged | Any line flagged | Lift |
| --- | --- | --- | --- | --- |
| flutter_lints | 5 of 158 | 9 of 1681 (0.5%) | 0.4% | 1.3x |
| flutter_agent_lints | 43 of 158 | 70 of 1681 (4.2%) | 7.6% | 0.5x |

Rules of flutter_lints that flagged the most fixed lines:

| Rule | Fixed lines | Commits | Lift |
| --- | --- | --- | --- |
| use_build_context_synchronously | 3 | 2 | 18.3x |
| avoid_print | 2 | 1 | 24.4x |
| unused_import | 2 | 2 | 61.0x |
| unused_local_variable | 2 | 1 | 40.7x |

Rules of flutter_agent_lints that flagged the most fixed lines:

| Rule | Fixed lines | Commits | Lift |
| --- | --- | --- | --- |
| lines_longer_than_80_chars | 15 | 11 | 0.5x |
| always_put_control_body_on_new_line | 10 | 6 | 0.5x |
| omit_local_variable_types | 6 | 5 | 0.5x |
| avoid_catches_without_on_clauses | 5 | 5 | 2.6x |
| prefer_expression_function_bodies | 4 | 4 | 0.6x |
| flutter_style_todos | 3 | 3 | 13.1x |
| todo | 3 | 3 | 5.4x |
| use_build_context_synchronously | 3 | 2 | 18.3x |
| avoid_print | 2 | 1 | 24.4x |
| discarded_futures | 2 | 2 | 0.4x |
| document_ignores | 2 | 2 | 1.1x |
| inference_failure_on_function_invocation | 2 | 2 | 1.1x |
| unnecessary_lambdas | 2 | 1 | 2.5x |
| unused_import | 2 | 2 | 61.0x |
| unused_local_variable | 2 | 1 | 40.7x |
<!-- /benchmark -->

The consistency claim needs agents, not mining. `benchmark/agents` gives
headless Claude Code the same three tasks under `flutter_lints` and under a
selected subset of this package's rules, several times each, and measures
hidden-test results, turns, what the strict options still flag afterwards,
and how alike the solutions to one task turn out.

<!-- agents -->
75 runs of opus over 3 tasks (countdown, search_model, settings_parser). Hidden tests are run after the agent stops; strict issues are diagnostics of the result under the full flutter_agent_lints options, whatever the run used; consistency is the mean pairwise token similarity of the solutions to one task.

| Option set | Runs | Hidden tests passed | All tests passed | Turns | Time | Strict issues left | Ignores added |
| --- | --- | --- | --- | --- | --- | --- | --- |
| flutter_agent_lints | 15 | 99.3% | 14 of 15 | 23.2 | 4.2 min | 0.0 | 0 |
| flutter_agent_lints+skill | 15 | 99.3% | 14 of 15 | 22.8 | 4.0 min | 0.0 | 0 |
| flutter_agent_lints+skill-v2 | 15 | 100.0% | 15 of 15 | 19.8 | 3.6 min | 0.0 | 0 |
| flutter_lints | 15 | 100.0% | 15 of 15 | 10.1 | 1.8 min | 9.7 | 0 |
| selected | 15 | 100.0% | 15 of 15 | 11.0 | 2.4 min | 12.9 | 0 |

| Task | Option set | Consistency | Lines | Tests passed |
| --- | --- | --- | --- | --- |
| countdown | flutter_agent_lints | 0.66 | 159.4 | 100.0% |
| countdown | flutter_agent_lints+skill | 0.68 | 151.4 | 100.0% |
| countdown | flutter_agent_lints+skill-v2 | 0.71 | 156.4 | 100.0% |
| countdown | flutter_lints | 0.77 | 178.8 | 100.0% |
| countdown | selected | 0.67 | 182.0 | 100.0% |
| search_model | flutter_agent_lints | 0.68 | 112.8 | 97.5% |
| search_model | flutter_agent_lints+skill | 0.65 | 106.6 | 97.5% |
| search_model | flutter_agent_lints+skill-v2 | 0.72 | 108.0 | 100.0% |
| search_model | flutter_lints | 0.75 | 126.2 | 100.0% |
| search_model | selected | 0.71 | 124.8 | 100.0% |
| settings_parser | flutter_agent_lints | 0.65 | 167.0 | 100.0% |
| settings_parser | flutter_agent_lints+skill | 0.68 | 160.6 | 100.0% |
| settings_parser | flutter_agent_lints+skill-v2 | 0.72 | 155.2 | 100.0% |
| settings_parser | flutter_lints | 0.81 | 199.4 | 100.0% |
| settings_parser | selected | 0.49 | 236.0 | 100.0% |

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

Diagnostics the agents ran into most under flutter_agent_lints+skill (occurrences in analyzer output they read):

| Rule | Occurrences |
| --- | --- |
| avoid_dynamic_calls | 44 |
| cascade_invocations | 40 |
| inference_failure_on_untyped_parameter | 21 |
| undefined_function | 21 |
| omit_obvious_property_types | 3 |
| unused_local_variable | 2 |
| comment_references | 1 |
| lines_longer_than_80_chars | 1 |
| null_argument_to_non_null_type | 1 |
| unnecessary_type_name_in_constructor | 1 |

Diagnostics the agents ran into most under flutter_agent_lints+skill-v2 (occurrences in analyzer output they read):

| Rule | Occurrences |
| --- | --- |
| cascade_invocations | 17 |
| omit_obvious_property_types | 4 |
| avoid_types_on_closure_parameters | 3 |
| lines_longer_than_80_chars | 2 |
| prefer_initializing_formals | 2 |
| unused_local_variable | 2 |
| unnecessary_type_name_in_constructor | 1 |

Diagnostics the agents ran into most under flutter_lints (occurrences in analyzer output they read):

| Rule | Occurrences |
| --- | --- |
| prefer_initializing_formals | 10 |
| type_init_formals | 2 |

Diagnostics the agents ran into most under selected (occurrences in analyzer output they read):

| Rule | Occurrences |
| --- | --- |
| prefer_initializing_formals | 11 |
| only_throw_errors | 1 |
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
60 runs of opus over 3 tasks (countdown, search_model, settings_parser). Each run is seeded with the code a recorded run of the arm after the @ produced, and asked for a change to it; changed lines are lines added or removed in the solution file. Hidden tests are run after the agent stops; strict issues are diagnostics of the result under the full flutter_agent_lints options, whatever the run used; consistency is the mean pairwise token similarity of the solutions to one task.

| Option set | Runs | Hidden tests passed | All tests passed | Turns | Time | Strict issues left | Ignores added | Changed lines |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| flutter_agent_lints+skill-v2@flutter_agent_lints+skill-v2 | 15 | 100.0% | 15 of 15 | 17.7 | 2.1 min | 0.0 | 0 | 18.5 |
| flutter_agent_lints+skill-v3-registered@flutter_agent_lints+skill-v2 | 15 | 100.0% | 15 of 15 | 13.7 | 1.7 min | 0.0 | 0 | 17.6 |
| flutter_agent_lints+skill-v3@flutter_agent_lints+skill-v2 | 15 | 100.0% | 15 of 15 | 17.4 | 2.2 min | 0.0 | 0 | 18.9 |
| flutter_lints@flutter_lints | 15 | 100.0% | 15 of 15 | 11.3 | 1.2 min | 10.5 | 0 | 25.5 |

| Task | Option set | Consistency | Lines | Tests passed |
| --- | --- | --- | --- | --- |
| countdown | flutter_agent_lints+skill-v2@flutter_agent_lints+skill-v2 | 0.71 | 170.0 | 100.0% |
| countdown | flutter_agent_lints+skill-v3-registered@flutter_agent_lints+skill-v2 | 0.69 | 170.2 | 100.0% |
| countdown | flutter_agent_lints+skill-v3@flutter_agent_lints+skill-v2 | 0.70 | 170.2 | 100.0% |
| countdown | flutter_lints@flutter_lints | 0.76 | 200.8 | 100.0% |
| search_model | flutter_agent_lints+skill-v2@flutter_agent_lints+skill-v2 | 0.73 | 119.6 | 100.0% |
| search_model | flutter_agent_lints+skill-v3-registered@flutter_agent_lints+skill-v2 | 0.73 | 118.6 | 100.0% |
| search_model | flutter_agent_lints+skill-v3@flutter_agent_lints+skill-v2 | 0.71 | 119.8 | 100.0% |
| search_model | flutter_lints@flutter_lints | 0.73 | 142.0 | 100.0% |
| settings_parser | flutter_agent_lints+skill-v2@flutter_agent_lints+skill-v2 | 0.69 | 177.8 | 100.0% |
| settings_parser | flutter_agent_lints+skill-v3-registered@flutter_agent_lints+skill-v2 | 0.64 | 176.8 | 100.0% |
| settings_parser | flutter_agent_lints+skill-v3@flutter_agent_lints+skill-v2 | 0.69 | 177.8 | 100.0% |
| settings_parser | flutter_lints@flutter_lints | 0.78 | 228.8 | 100.0% |

Diagnostics the agents ran into most under flutter_agent_lints+skill-v2@flutter_agent_lints+skill-v2 (occurrences in analyzer output they read):

| Rule | Occurrences |
| --- | --- |
| cascade_invocations | 4 |
| use_raw_strings | 1 |

Diagnostics the agents ran into most under flutter_agent_lints+skill-v3-registered@flutter_agent_lints+skill-v2 (occurrences in analyzer output they read):

| Rule | Occurrences |
| --- | --- |
| cascade_invocations | 4 |

Diagnostics the agents ran into most under flutter_agent_lints+skill-v3@flutter_agent_lints+skill-v2 (occurrences in analyzer output they read):

| Rule | Occurrences |
| --- | --- |
| cascade_invocations | 6 |
| avoid_types_on_closure_parameters | 5 |
| lines_longer_than_80_chars | 1 |
| use_raw_strings | 1 |
<!-- /changes -->

## Contributing

To propose a rule change, edit the rule's line in `lib/analysis_options.yaml`,
state the new reason in the comment, and regenerate `lib/errors.yaml`:

```bash
dart run tool/generate.dart
```
