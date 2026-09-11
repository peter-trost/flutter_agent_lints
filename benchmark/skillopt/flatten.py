"""Flattens the shipped skill into the single file SkillOpt trains on.

SkillOpt optimizes one Markdown document. The skill ships as SKILL.md plus
two references, so training runs on their concatenation and the result is
split back by the same headings afterwards.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SKILL = REPO / "skills" / "flutter_agent_lints-strict-dart"


def body(path: Path) -> str:
    text = path.read_text(encoding="utf-8")
    return re.sub(r"\A---\n.*?\n---\n", "", text, count=1, flags=re.S).strip()


def flatten() -> str:
    # The pointer section only makes sense with separate files.
    main = re.sub(r"## Read the reference for what you are writing\n.*?(?=\n## )", "", body(SKILL / "SKILL.md"), flags=re.S)
    parts = [main.strip()]
    for ref in ("dart", "flutter"):
        text = body(SKILL / "references" / f"{ref}.md")
        parts.append(f"<!-- reference: {ref} -->\n{text}")
    return "\n\n".join(parts) + "\n"


def main() -> None:
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else SKILL.parent.parent / "benchmark" / "skillopt" / "env" / "skills" / "initial.md"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(flatten(), encoding="utf-8")
    print(f"{out}: {len(out.read_text().splitlines())} lines")


if __name__ == "__main__":
    main()
