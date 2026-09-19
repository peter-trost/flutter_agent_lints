# Benchmark: what the options do to an agent

`bin/agents.dart` gives headless Claude Code (`claude -p`, billed to the
local login) each task under `agents/tasks` once per arm, `--reps` times,
in a fresh copy of `agents/base` outside the repository so no project
settings or hooks leak in. The arms are `flutter_lints`,
`flutter_agent_lints`, and `flutter_agent_lints+skill`, which installs the
skill under `skills/` the way `dart run skills@ get` does; pass `--configs`
to run others.

Per run it records turns and tokens from the CLI's result event, the
hidden tests of the task (copied in only after the agent stopped), every
rule code in analyzer output the agent read, lines of Dart under `lib/`,
and any `ignore` comment or edit to `analysis_options.yaml` the prompt
forbade.

With `--change`, a task under `agents/changes` asks for one feature on top
of the base task, and each run starts from the `lib/` the same arm
produced on the base task in the greenfield batch, with the base task's
hidden tests in place as the project's own tests. The record then also
carries the lines added or removed in the solution file. Run the
greenfield batch first; the seeds are read from `results/agents/outputs/`,
which is not committed.

```bash
dart pub get
dart run bin/agents.dart --validate            # references pass their hidden tests
dart run bin/agents.dart --validate --change
dart run bin/agents.dart                       # greenfield
dart run bin/agents.dart --change              # one feature on top
dart run bin/agents_report.dart                # tables into the README
```

Runs already recorded in `results/agents/*.jsonl` are skipped, so an
interrupted batch resumes. Records are append-only: to measure again, run
with another `--model`, or move the results files aside and start over.
CI checks the README tables against the records.

## Limits

- A task prompt fixes the public API so the hidden tests compile, which
  already narrows the solution space for every arm.
- The user-level `CLAUDE.md` of whoever runs the batch is loaded by the CLI
  and applies to every arm alike.
- Five runs per cell describe this batch, not the population; the spread
  between runs of one cell is about a fifth of the mean for turns.
- The `search_model` prompt is ambiguous about when `loading` begins, and
  the one hidden-test failure recorded so far is that reading. The prompt
  is left as it is so recorded runs stay comparable.
