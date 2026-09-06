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
