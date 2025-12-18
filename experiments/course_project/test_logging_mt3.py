"""
Quick Test Script for MT3 Logging Verification
Tests multi-task metrics including per-task success rates
"""
import sys
sys.path.insert(0, '/source')

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
    seed: int = 42
    track: bool = False
    wandb_project: str | None = None
    wandb_entity: str | None = None
    data_dir: Path = Path("./experiment_results")


def main() -> None:
    args = tyro.cli(Args)

    num_tasks = 3

    experiment = Experiment(
        exp_name="LOGGING_TEST_MT3",
        seed=args.seed,
        data_dir=args.data_dir,
        env=MetaworldConfig(
            env_id="MT3",
            use_one_hot=True,
            terminate_on_success=False,
        ),
        algorithm=MTSACConfig(
            num_tasks=num_tasks,
            gamma=0.99,
            actor_config=ContinuousActionPolicyConfig(
                network_config=MultiHeadConfig(
                    num_tasks=num_tasks,
                    width=256,  # Smaller for faster testing
                    optimizer=OptimizerConfig(max_grad_norm=1.0),
                )
            ),
            critic_config=QValueFunctionConfig(
                network_config=MultiHeadConfig(
                    num_tasks=num_tasks,
                    width=256,  # Smaller for faster testing
                    optimizer=OptimizerConfig(max_grad_norm=1.0),
                )
            ),
            num_critics=2,
        ),
        training_config=OffPolicyTrainingConfig(
            evaluation_frequency=30,  # Evaluate every 30 episodes (very frequent!)
            total_steps=int(100_000),  # Short run
            buffer_size=int(9_000),  # Divisible by 3
            batch_size=129,  # Must be divisible by 3
        ),
        checkpoint=False,  # No checkpointing for quick test
        resume=False,
    )

    if args.track:
        experiment.enable_wandb(
            project=args.wandb_project,
            entity=args.wandb_entity,
            config=experiment,
            tags=["logging-test", "mt3", "debug"],
        )

    experiment.run()


if __name__ == "__main__":
    main()
