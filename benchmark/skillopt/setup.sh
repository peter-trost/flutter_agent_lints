#!/usr/bin/env bash
# Links this environment into a SkillOpt checkout and registers it.
#
#   benchmark/skillopt/setup.sh /path/to/SkillOpt-src
#
# SkillOpt discovers environments under skillopt/envs/<name> and configs
# under configs/<name>, and registers adapters in scripts/train.py and
# scripts/eval_only.py. Nothing here is copied: the checkout gets symlinks
# into this repository, so the env, prompts, tasks and config stay
# versioned here.
set -euo pipefail

src="${1:?path to the SkillOpt checkout}"
here="$(cd "$(dirname "$0")" && pwd)"

ln -sfn "$here/env" "$src/skillopt/envs/strictdart"
ln -sfn "$here/configs" "$src/configs/strictdart"

register() {
  local script="$1"
  if grep -q 'strictdart' "$script"; then
    return
  fi
  python3 - "$script" <<'PY'
import sys, re
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
block = (
    "    try:\n"
    "        from skillopt.envs.strictdart.adapter import StrictDartAdapter\n"
    "        _ENV_REGISTRY[\"strictdart\"] = StrictDartAdapter\n"
    "    except ImportError:\n"
    "        pass\n"
)
marker = "def _register_builtins() -> None:\n"
i = text.index(marker) + len(marker)
# Skip the docstring line if present.
rest = text[i:]
m = re.match(r'(\s*""".*?"""\n)', rest, re.S)
if m:
    i += len(m.group(1))
text = text[:i] + block + text[i:]
open(path, "w", encoding="utf-8").write(text)
PY
}
register "$src/scripts/train.py"
register "$src/scripts/eval_only.py"

python3 "$here/flatten.py" "$here/env/skills/initial.md"
python3 "$here/tasks.py"

echo "linked: $src/skillopt/envs/strictdart -> $here/env"
echo "linked: $src/configs/strictdart -> $here/configs"
echo "registered strictdart in scripts/train.py and scripts/eval_only.py"
