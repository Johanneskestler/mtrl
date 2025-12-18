"""
Multi-Task MTMHSAC Training for MT3 (reach, push, pick-place)
Course Project: From Single-Task to Multi-Task RL

Based on mt10_mtmhsac.py with custom MT3 benchmark
Trains on 3 tasks: reach-v3, push-v3, pick-place-v3
"""
import sys
sys.path.insert(0, '/source')  # Ensure mounted source takes precedence

from dataclasses import dataclass
from pathlib import Path

import tyro

from mtrl.config.networks import ContinuousActionPolicyConfig, QValueFunctionConfig
from mtrl.config.nn import MultiHeadConfig
from mtrl.config.optim import OptimizerConfig
from mtrl.config.rl import OffPolicyTrainingConfig
from mtrl.envs import MetaworldConfig
from mtrl.experiment import Experiment
from mtrl.rl.algorithms import MTSACConfig


@dataclass(frozen=True)
class Args:
    seed: int = 1
    track: bool = False
    wandb_project: str | None = None
    wandb_entity: str | None = None
    data_dir: Path = Path("./experiment_results")
    resume: bool = False


def main() -> None:
    args = tyro.cli(Args)

    experiment = Experiment(
        exp_name="mt3_mtmhsac",
        seed=args.seed,
        data_dir=args.data_dir,
        env=MetaworldConfig(
            env_id="MT3",
            use_one_hot=True,
            terminate_on_success=False,
        ),
        algorithm=MTSACConfig(
            num_tasks=3,
            gamma=0.99,
            actor_config=ContinuousActionPolicyConfig(
                network_config=MultiHeadConfig(
                    num_tasks=3,
                    optimizer=OptimizerConfig(max_grad_norm=1.0)
                )
            ),
            critic_config=QValueFunctionConfig(
                network_config=MultiHeadConfig(
                    num_tasks=3,
                    optimizer=OptimizerConfig(max_grad_norm=1.0),
                )
            ),
            num_critics=2,
        ),
        training_config=OffPolicyTrainingConfig(
            evaluation_frequency=200,
            total_steps=int(2_000_000),
            buffer_size=int(300_000),
            batch_size=384,
        ),
        checkpoint=True,
        resume=args.resume,
    )

    if args.track:
        experiment.enable_wandb(
            project=args.wandb_project,
            entity=args.wandb_entity,
            config=experiment,
            resume="allow",
        )

    experiment.run()


if __name__ == "__main__":
    main()
