"""Single-shot rollout: prompt plus skill in, one Dart file out, analyzed.

The score is first-pass cleanliness, which is what the skill exists to
raise: the target answers once with the complete file, the analyzer runs
under the package's own ruleset, and the diagnostics on that first draft
are the loss. A usage stub that must compile against the file keeps the
target honest about the requested API.

Analysis happens in one shared Flutter workspace (a copy of the agent
benchmark's base app with the ruleset included), one subdirectory per
rollout, so Flutter resolves for widget tasks.
"""
from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import tempfile
import threading
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from skillopt.model import chat_target
from skillopt.prompts import load_prompt

# The env directory is a symlink into the repository; resolving it finds
# benchmark/skillopt/env, three levels below the repository root.
_REPO_ROOT = Path(__file__).resolve().parents[3]
_FENCE = re.compile(r"```dart\s*\n(.*?)```", re.S)
_WORKSPACE_LOCK = threading.Lock()
_WORKSPACE: Path | None = None

# Diagnostics a file earns only because nothing else references it. A
# complete solution file is analyzed alone, so these carry no signal.
_ISOLATION_ONLY = {"unused_element", "unused_field", "unused_local_variable"}


def _workspace() -> Path:
    """A resolved Flutter package with the ruleset included, built once."""
    global _WORKSPACE
    with _WORKSPACE_LOCK:
        if _WORKSPACE is not None:
            return _WORKSPACE
        ws = Path(tempfile.gettempdir()) / "skillopt_strictdart_ws"
        if not (ws / ".dart_tool" / "package_config.json").exists():
            if ws.exists():
                shutil.rmtree(ws)
            shutil.copytree(_REPO_ROOT / "benchmark" / "agents" / "base", ws)
            (ws / "analysis_options.yaml").write_text(
                f"include: {_REPO_ROOT}/lib/analysis_options.yaml\n", encoding="utf-8"
            )
            subprocess.run(["flutter", "pub", "get"], cwd=ws, check=True, capture_output=True)
            # pub get appends excludes; keep the include first so it wins.
        _WORKSPACE = ws
        return ws


def _analyze(target_dir: Path) -> list[dict]:
    proc = subprocess.run(
        ["dart", "analyze", "--format=json", str(target_dir)],
        cwd=_workspace(),
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    out = proc.stdout or ""
    start = out.find("{")
    if start < 0:
        raise RuntimeError(f"analyzer produced no report: {proc.stderr}")
    return json.loads(out[start:])["diagnostics"]


def _describe(diagnostics: list[dict]) -> str:
    lines = []
    for d in diagnostics:
        loc = d["location"]
        line = loc["range"]["start"]["line"]
        name = Path(loc["file"]).name
        lines.append(f"{name}:{line} {d['problemMessage']} [{d['code']}]")
    return "\n".join(lines)


def _score(code: str, item: dict, rollout_dir: Path) -> tuple[int, float, str, str]:
    """Analyze one answer. Returns hard, soft, analyzer text, fail reason."""
    ws = _workspace()
    sub = f"r_{re.sub(r'[^a-z0-9]', '_', item['id'].lower())}"
    target = ws / "lib" / sub
    if target.exists():
        shutil.rmtree(target)
    target.mkdir(parents=True)
    solution_name = Path(item["file"]).name
    (target / solution_name).write_text(code, encoding="utf-8")
    usage = item.get("usage", "").strip()
    if usage:
        usage_src = (
            f"import 'package:task_app/{sub}/{solution_name}';\n\n{usage}\n"
        )
        (target / "usage.dart").write_text(usage_src, encoding="utf-8")
    try:
        diagnostics = _analyze(target)
    finally:
        # Keep a copy for inspection, clear the workspace slot.
        shutil.copytree(target, rollout_dir / "files", dirs_exist_ok=True)
        shutil.rmtree(target, ignore_errors=True)

    solution = [
        d for d in diagnostics
        if Path(d["location"]["file"]).name == solution_name
        and d["code"] not in _ISOLATION_ONLY
    ]
    usage_errors = [
        d for d in diagnostics
        if Path(d["location"]["file"]).name == "usage.dart"
        and d["type"] in {"COMPILE_TIME_ERROR", "SYNTACTIC_ERROR"}
    ]
    report = _describe(solution + usage_errors) or "No issues found."
    if usage_errors:
        return 0, 0.0, report, f"the requested API does not compile: {usage_errors[0]['problemMessage']}"
    n = len(solution)
    if n == 0:
        return 1, 1.0, report, ""
    codes = sorted({d["code"] for d in solution})
    return 0, max(0.0, 1.0 - n / 10.0), report, f"{n} diagnostics on the first draft: {', '.join(codes[:6])}"


def _rollout_one(item: dict, skill_content: str, *, prediction_dir: Path,
                 max_completion_tokens: int, timeout: int) -> dict:
    system = load_prompt("rollout_system", env="strictdart").format(skill=skill_content.strip())
    user = (
        f"{item['prompt'].strip()}\n\n"
        f"Reply with the complete contents of `{item['file']}` in a single "
        "```dart fenced block and nothing else."
    )
    rollout_dir = prediction_dir / str(item["id"])
    rollout_dir.mkdir(parents=True, exist_ok=True)

    fail_reason = ""
    try:
        answer, _usage = chat_target(
            system=system, user=user,
            max_completion_tokens=max_completion_tokens, timeout=timeout,
        )
    except Exception as exc:  # noqa: BLE001
        # A usage limit or a logged-out CLI would otherwise score as a run
        # of failures and teach the optimizer nonsense; stop the run instead.
        text = str(exc).lower()
        if any(word in text for word in ("limit", "logged in", "login", "auth")):
            raise RuntimeError(f"target unavailable, aborting the run: {exc}") from exc
        answer, fail_reason = "", f"target call failed: {exc}"

    match = _FENCE.search(answer or "")
    if match is None:
        hard, soft, report = 0, 0.0, "No ```dart block in the reply."
        fail_reason = fail_reason or "the reply had no ```dart block"
    else:
        hard, soft, report, fail_reason = _score(match.group(1), item, rollout_dir)

    conversation = [
        {"role": "system", "content": system},
        {"role": "user", "content": user},
        {"role": "assistant", "content": answer},
        {"role": "system", "content": f"dart analyze on the reply:\n{report}"},
    ]
    (rollout_dir / "conversation.json").write_text(
        json.dumps(conversation, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    return {
        "id": str(item["id"]),
        "hard": hard,
        "soft": soft,
        "predicted_answer": answer,
        "task_description": item["prompt"],
        "question": item["prompt"],
        "task_type": item.get("task_type", "dart"),
        "fail_reason": fail_reason,
        "analyzer_report": report,
        "target_system_prompt": system,
        "target_user_prompt": user,
        "n_turns": 1,
    }


def run_batch(*, items: list[dict], skill_content: str, out_root: str,
              workers: int = 3, max_completion_tokens: int = 8192,
              timeout: int = 300) -> list[dict]:
    os.makedirs(out_root, exist_ok=True)
    prediction_dir = Path(out_root, "predictions")
    _workspace()
    with ThreadPoolExecutor(max_workers=max(1, workers)) as pool:
        results = list(pool.map(
            lambda it: _rollout_one(
                it, skill_content, prediction_dir=prediction_dir,
                max_completion_tokens=max_completion_tokens, timeout=timeout,
            ),
            items,
        ))
    Path(out_root, "rollouts.json").write_text(
        json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    if results and all(r["fail_reason"].startswith("target call failed") for r in results):
        raise RuntimeError(f"every rollout in the batch failed: {results[0]['fail_reason']}")
    return results
