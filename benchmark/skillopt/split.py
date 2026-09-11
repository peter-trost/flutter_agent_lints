"""Writes a trained skill document back into the three shipped skill files.

The inverse of flatten.py: the text before the first reference marker is
the SKILL.md body, each marker starts a reference. The frontmatter and the
pointer section that flatten removed come from the current SKILL.md, and
SkillOpt's machine-managed regions are kept as ordinary text with their
markers removed, so a reviewer sees them as plain edits.

    python3 benchmark/skillopt/split.py outputs/strictdart/best_skill.md
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SKILL = REPO / "skills" / "flutter_agent_lints-strict-dart"
POINTER = """## Read the reference for what you are writing

- **[references/dart.md](references/dart.md)** — always. Constructors,
  initializing formals, cascades, equality, the strict type modes, and the
  rules `dart fix` handles for you.
- **[references/flutter.md](references/flutter.md)** — only when the file
  imports Flutter. Widget constructors and keys, const, child-last, and
  `BuildContext` after an await. Those rules cannot fire in a pure Dart
  package.
"""
_MACHINE = re.compile(r"<!--\s*/?(SLOW_UPDATE|APPENDIX)_(START|END)\s*-->\n?")


def split(trained: str) -> dict[Path, str]:
    trained = _MACHINE.sub("", trained)
    parts = re.split(r"<!-- reference: (\w+) -->\n", trained)
    main, rest = parts[0].strip(), parts[1:]
    refs = {rest[i]: rest[i + 1].strip() for i in range(0, len(rest), 2)}
    if set(refs) != {"dart", "flutter"}:
        raise SystemExit(f"expected dart and flutter references, found {sorted(refs)}")

    current = (SKILL / "SKILL.md").read_text(encoding="utf-8")
    frontmatter = re.match(r"\A---\n.*?\n---\n", current, re.S).group(0)
    # The pointer section goes back where flatten took it from: before the
    # first section after the intro.
    first_heading = re.search(r"^## ", main, re.M)
    if first_heading:
        i = first_heading.start()
        main = f"{main[:i]}{POINTER}\n{main[i:]}"
    else:
        main = f"{main}\n\n{POINTER}"
    main = re.sub(r"\n{3,}", "\n\n", main)
    return {
        SKILL / "SKILL.md": f"{frontmatter}\n{main.strip()}\n",
        SKILL / "references" / "dart.md": f"{refs['dart']}\n",
        SKILL / "references" / "flutter.md": f"{refs['flutter']}\n",
    }


def main() -> None:
    source = Path(sys.argv[1])
    for path, text in split(source.read_text(encoding="utf-8")).items():
        path.write_text(text, encoding="utf-8")
        print(f"wrote {path.relative_to(REPO)} ({len(text.splitlines())} lines)")


if __name__ == "__main__":
    main()
