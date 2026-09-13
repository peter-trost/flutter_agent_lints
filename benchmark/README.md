# Benchmark: what the options do to an agent

`bin/agents.dart` gives headless Claude Code (`claude -p`, billed to the
local login) each task under `agents/tasks` once per option set under
`agents/options`, `--reps` times, in a fresh copy of `agents/base` outside
the repository so no project settings or hooks leak in.

Per run it records the turn count, duration and token usage from the CLI's
result event; the hidden tests of the task (copied in only after the agent
stopped); the diagnostics left under the run's own options and under the
full `flutter_agent_lints` options; `ignore` comments added; whether the
agent edited `analysis_options.yaml`; every rule code in analyzer output
the agent read (the fix-loop price of the option set); and the solution
file, from which the report computes the mean pairwise token similarity of
the solutions to one task as the consistency measure.

```bash
dart pub get
dart run bin/agents.dart --validate            # references pass their hidden tests
dart run bin/agents.dart --model opus --reps 5 # 3 tasks × 2 option sets × 5
dart run bin/agents_report.dart
```

A config is the name of a file under `agents/options`. `<options>+skill`
runs those options with the skill the package ships installed in the
workdir the way `dart run skills@ get` installs it, and `+skill-<label>`
names the arm so two versions of the skill can be measured side by side.
The `flutter_agent_lints+skill-v2` greenfield rows were recorded before the
runner registered the skill with the CLI, so the agent found it by listing
`.claude/` and read its files by hand; they stay because their outputs
seed the change runs. Every other skill row was run with the skill
registered.

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
dart run bin/agents.dart --change --reps 5 --configs flutter_lints@flutter_lints
```

`bin/agents_report.dart` renders both results files into the README; CI
runs it with `--check` so the tables cannot drift from the results.

## Limits

- A task prompt fixes the public API so the hidden tests compile, which
  already narrows the solution space for both arms.
- The user-level `CLAUDE.md` of whoever runs the batch is loaded by the CLI
  and applies to both arms alike.
- With five runs per cell the numbers describe this batch, not the
  population.
- The `search_model` prompt is ambiguous about when `loading` begins: it
  says status is `loading` while a fetch is in flight, without saying what
  it is during the debounce that precedes one. Every hidden-test failure so
  far, in any arm, has been that one reading. That is a defect in the task
  rather than a difference between option sets, and the prompt is left as
  it is so the recorded runs stay comparable.
