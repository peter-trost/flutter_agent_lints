"""Wires the loader and the rollout into SkillOpt's lifecycle."""
from __future__ import annotations

from skillopt.datasets.base import BatchSpec
from skillopt.envs.base import EnvAdapter
from skillopt.envs.strictdart.dataloader import StrictDartDataLoader
from skillopt.envs.strictdart.rollout import run_batch


class StrictDartAdapter(EnvAdapter):
    def __init__(
        self,
        split_dir: str = "",
        data_path: str = "",
        split_mode: str = "split_dir",
        split_ratio: str = "2:1:7",
        split_seed: int = 42,
        split_output_dir: str = "",
        workers: int = 3,
        analyst_workers: int = 2,
        failure_only: bool = False,
        minibatch_size: int = 5,
        edit_budget: int = 3,
        seed: int = 42,
        limit: int = 0,
        max_completion_tokens: int = 8192,
        exec_timeout: int = 300,
    ) -> None:
        self.workers = workers
        self.analyst_workers = analyst_workers
        self.failure_only = failure_only
        self.minibatch_size = minibatch_size
        self.edit_budget = edit_budget
        self.max_completion_tokens = int(max_completion_tokens)
        self.exec_timeout = int(exec_timeout)
        self.dataloader = StrictDartDataLoader(
            split_dir=split_dir,
            data_path=data_path,
            split_mode=split_mode,
            split_ratio=split_ratio,
            split_seed=split_seed,
            split_output_dir=split_output_dir,
            seed=seed,
            limit=limit,
        )

    def setup(self, cfg: dict) -> None:
        super().setup(cfg)
        self.dataloader.setup(cfg)

    def get_dataloader(self):
        return self.dataloader

    def build_env_from_batch(self, batch: BatchSpec, **kwargs):
        return list(batch.payload or [])

    def build_train_env(self, batch_size: int, seed: int, **kwargs):
        batch = self.dataloader.build_train_batch(batch_size=batch_size, seed=seed, **kwargs)
        return self.build_env_from_batch(batch, **kwargs)

    def build_eval_env(self, env_num: int, split: str, seed: int, **kwargs):
        batch = self.dataloader.build_eval_batch(env_num=env_num, split=split, seed=seed, **kwargs)
        return self.build_env_from_batch(batch, **kwargs)

    def rollout(self, env_manager, skill_content: str, out_dir: str, **kwargs) -> list[dict]:
        return run_batch(
            items=list(env_manager),
            skill_content=skill_content,
            out_root=out_dir,
            workers=self.workers,
            max_completion_tokens=self.max_completion_tokens,
            timeout=self.exec_timeout,
        )

    def get_task_types(self) -> list[str]:
        seen: list[str] = []
        for item in self.dataloader.train_items + self.dataloader.val_items + self.dataloader.test_items:
            tt = str(item.get("task_type") or "dart")
            if tt not in seen:
                seen.append(tt)
        return seen or ["dart"]
