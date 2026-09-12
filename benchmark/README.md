# Benchmark: would the options have flagged real bug fixes?

This package measures one thing: how often the lines that a human later fixed
carried a diagnostic before the fix, under `flutter_lints` (the default of
`flutter create`) and under `flutter_agent_lints`. It follows the method of
Gao, Bird and Barr, *To Type or Not to Type: Quantifying Detectable Bugs in
JavaScript* (ICSE 2017), which asked the same question of static types.

## Method

1. `corpus.yaml` lists Flutter apps that commit their generated code. For
   each, `bin/run.dart` takes the non-merge commits of the last year whose
   subject contains *fix*, *fixes*, *fixed*, *bug* or *crash* and that
   modify Dart files under `lib/`. Commits touching more than 5 files, more
   than 200 fixed lines, only generated files, or only adding lines are
   skipped; the results file records every skip and its reason.
2. Each option set is written as the package's `analysis_options.yaml` in
   turn and `dart analyze` runs on the touched files at the parent commit.
   Compile and syntax errors are ignored: they fire under any options, and
   they also appear when an old commit does not build against the installed
   SDK.
3. A **fixed line** is a line the fix deleted or replaced. It counts as
   **flagged** when it carried a diagnostic at the parent commit and no
   diagnostic with the same code sits on the fix's replacement lines in that
   file. The second condition removes rules that fire regardless of the bug.
4. **Density** is the share of all lines in the touched files that carry a
   diagnostic. **Lift** divides the flagged share of fixed lines by it. A
   lift of one means the option set points at fixed lines no more often
   than at any line; the strict set flags so many lines that its raw rate
   alone would mean little. The per-rule table applies the same ratio to
   each rule, so a style rule that happens to sit on rewritten lines
   shows a lift near one while a rule that describes the bug shows a
   high one.

`bin/report.dart` renders `results/*.json` into the README section between
the benchmark markers; CI runs it with `--check` so the table cannot drift
from the results.

## Running

```bash
dart pub get
dart run bin/run.dart            # all repositories, resumes where it stopped
dart run bin/run.dart --limit 5 localsend
dart run bin/report.dart
```

Repositories are cloned into `.cache/` with `--filter=blob:none`. Each
commit costs a checkout, a `flutter pub get` and two analyzer runs, about a
minute. A commit whose dependencies no longer resolve with the installed
Flutter SDK, even without its lockfile, is skipped.

## Limits

- The commit filter is a keyword heuristic. Some matches are not bug fixes
  and some bug fixes are not matched.
- Line overlap is a proxy for causation. A rule can sit on a fixed line
  without describing the bug, which is why lift and the per-rule table are
  reported rather than a single number.
- Diagnostics on a fixed line say nothing about the cost of the rule
  elsewhere. That question needs agent runs, not mining.

## Agent runs

`agents/` measures what mining cannot: how an option set changes what an
agent produces. `bin/agents.dart` gives headless Claude Code (`claude -p`,
billed to the local login) each task under `agents/tasks` once per option
set under `agents/options`, `--reps` times, in a fresh copy of `agents/base`
outside the repository so no project settings or hooks leak in.

Per run it records the turn count, duration and token usage from the CLI's
result event; the hidden tests of the task (copied in only after the agent
stopped); the diagnostics left under the run's own options and under the
full `flutter_agent_lints` options; `ignore` comments added; whether the
agent edited `analysis_options.yaml`; every rule code in analyzer output
the agent read (the fix-loop price of the option set); and the solution
file, from which the report computes the mean pairwise token similarity of
the solutions to one task as the consistency measure.

```bash
dart run bin/agents.dart --validate            # references pass their hidden tests
dart run bin/agents.dart --model opus --reps 5 # 3 tasks × 2 option sets × 5
dart run bin/agents_report.dart
```

The option sets are `flutter_lints` and `selected`: `flutter_lints` plus the
rules of this package that are about robustness, as errors. The full package
was not used as an arm because its style rules would dominate the fix loop
and drown the question.

`agents/changes` asks the other half of the question: whether code
written under a strict option set is cheaper for an agent to change later.
Each change task names a base task and asks for one feature on top of it.
With `--change`, a config is `<options>@<seed>`, and rep `n` starts from
the `lib/` that rep `n` of the seed config produced on the base task, with
the base task's hidden tests in place as the project's own tests. The
hidden tests are then the base task's plus the change's, and the record
also carries the lines added or removed in the solution file. Records go
to `results/agents/changes.jsonl` and render between the README's
`changes` markers.

```bash
dart run bin/agents.dart --validate --change   # change references pass
dart run bin/agents.dart --change --reps 5 \
  --configs flutter_lints@flutter_lints,flutter_agent_lints+skill-v2@flutter_agent_lints+skill-v2
```

Runs recorded before the `+skill-v3-registered` arm were made with
`--disable-slash-commands`, which also disables skill registration: the
agent was never told the skill existed and found it, when it did, by
listing `.claude/`. Those arms overstate the skill's cost by the search
and the manual reads.

Limits: a task prompt fixes the public API so the hidden tests compile,
which already narrows the solution space for both arms; the user-level
`CLAUDE.md` of whoever runs the batch is loaded by the CLI and applies to
both arms alike; with five runs per cell the numbers describe this batch,
not the population.

The `search_model` prompt is also ambiguous about when `loading` begins: it
says status is `loading` while a fetch is in flight, without saying what it
is during the debounce that precedes one. Every hidden-test failure so far,
in any arm, has been that one reading. Those are a defect in the task rather
than a difference between option sets, and the prompt is left as it is so
the recorded runs stay comparable.
