"""Loads the task splits: one ``tasks.json`` array per split directory."""
from __future__ import annotations

import json
from pathlib import Path

from skillopt.datasets.base import SplitDataLoader


def _normalize(raw: dict) -> dict:
    return {
        "id": str(raw["id"]),
        "task_type": str(raw.get("task_type") or "dart"),
        "prompt": str(raw["prompt"]),
        "file": str(raw["file"]),
        "usage": str(raw.get("usage") or ""),
    }


class StrictDartDataLoader(SplitDataLoader):
    def load_split_items(self, split_path: str) -> list[dict]:
        path = Path(split_path) / "tasks.json"
        if not path.exists():
            raise FileNotFoundError(f"no tasks.json in {split_path}")
        with path.open(encoding="utf-8") as f:
            return [_normalize(item) for item in json.load(f)]
