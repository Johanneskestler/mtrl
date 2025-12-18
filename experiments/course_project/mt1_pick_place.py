"""
Single-Task SAC Training for Pick-Place Task
Course Project: From Single-Task to Multi-Task RL
"""
import sys
sys.path.insert(0, '/source')  # Ensure mounted source takes precedence

from dataclasses import dataclass
from pathlib import Path

import tyro

from mtrl.config.networks import ContinuousActionPolicyConfig, QValueFunctionConfig
from mtrl.config.nn import VanillaNetworkConfig
from mtrl.config.optim import OptimizerConfig
from mtrl.config.rl import OffPolicyTrainingConfig
from mtrl.envs import MetaworldConfig
from mtrl.experiment import Experiment
from mtrl.rl.algorithms import SACConfig


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

    num_tasks = 1

    experiment = Experiment(
        exp_name="ST_SAC_pick_place_v3",
        seed=args.seed,
        data_dir=args.data_dir,
        env=MetaworldConfig(
            env_id="MT1",
            task_name="pick-place-v3",
            terminate_on_success=False,
        ),
        algorithm=SACConfig(
            num_tasks=num_tasks,
            gamma=0.99,
            actor_config=ContinuousActionPolicyConfig(
                network_config=VanillaNetworkConfig(
                    width=1024,
                    optimizer=OptimizerConfig(max_grad_norm=1.0)
                )
            ),
            critic_config=QValueFunctionConfig(
                network_config=VanillaNetworkConfig(
                    width=1024,
                    optimizer=OptimizerConfig(max_grad_norm=1.0)
                )
            ),
            num_critics=2,
        ),
        training_config=OffPolicyTrainingConfig(
            evaluation_frequency=200,
            total_steps=int(2_000_000),
            buffer_size=int(100_000),
            batch_size=128,
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
            tags=["single-task", "sac", "pick-place", "course-project"],
        )

    experiment.run()


if __name__ == "__main__":
    main()
