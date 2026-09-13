# Optimizing the skill with SkillOpt

[SkillOpt](https://github.com/microsoft/SkillOpt) treats a skill document as
trainable weights: run the target model on a batch of tasks, have an
optimizer model propose bounded edits from the failures, keep an edit only
when a held-out validation split scores higher. This directory is the
environment that lets it train `skills/flutter_agent_lints-strict-dart`.

## What is optimized

First-pass cleanliness. Each task asks for one Dart file with a fixed
public API; the target answers once, in a single `claude -p` call with the
skill as its system prompt; the answer is analyzed under
`lib/analysis_options.yaml` in a Flutter workspace; the score is `hard = 1`
when the first draft has no diagnostics and the usage stub compiles against
it, and `soft = 1 - diagnostics / 10`. The usage stub is what keeps the
target honest about the requested API.

Single-shot, not agentic, on purpose: first-pass quality is a property of
one completion, and a completion costs about a thirtieth of an agentic run.
The trained skill is then measured the expensive way, by the agent benchmark
in `benchmark/agents`, which is the only test that counts.

## Layout

- `env/`: the SkillOpt environment (loader, rollout, adapter), its
  reflection prompts, and the task splits under `env/data/`. Symlinked into
  a SkillOpt checkout as `skillopt/envs/strictdart`.
- `configs/default.yaml`: the run. Both roles go through the local `claude`
  login; sizes are the smallest the validation gate can resolve.
- `tasks.py`: writes the splits. 23 training and 12 validation tasks chosen
  to exercise the rules that fire in practice; the 3 agent-benchmark tasks
  form the test split.
- `flatten.py`: SkillOpt trains one Markdown file, so the skill's three
  files are concatenated into `env/skills/initial.md` (generated, not
  committed) and the result is split back by the reference markers.
- `setup.sh`: links and registers the environment in a checkout.

## Running

```bash
git clone --depth 1 https://github.com/microsoft/SkillOpt.git ../SkillOpt-src
cd ../SkillOpt-src && uv venv .venv && VIRTUAL_ENV=$PWD/.venv uv pip install -e .
cd - && benchmark/skillopt/setup.sh ../SkillOpt-src
cd ../SkillOpt-src
CLAUDE_SETTING_SOURCES=project .venv/bin/python -u scripts/train.py \
  --config configs/strictdart/default.yaml --out_root outputs/strictdart
```

The run writes `outputs/strictdart/best_skill.md`. Split it back into the
three skill files by the `<!-- reference: ... -->` markers, then run
`dart run tool/check_skill.dart` and `dart run tool/check_samples.dart`
before trusting a single edit: the gate only verifies edits against the
validation tasks, and an edit can be a false claim about a rule that those
tasks happen not to exercise. The smoke run produced exactly that.

## Limits

- The gate resolves in steps of one validation task, so a 12-task split
  cannot see changes under about 8 points.
- A skill that is already near the ceiling in single-shot mode gives the
  optimizer little to learn from; the baseline score says whether a run is
  worth its budget before the first step.
- The optimizer sees analyzer output, not the rules' reasons, and can
  propose edits that satisfy a task by weakening the guidance. Read every
  accepted edit.
