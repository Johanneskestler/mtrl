"""
Quick Test Script for Logging Verification
Runs with very frequent evaluation to check if all metrics are logged correctly
"""
import sys
sys.path.insert(0, '/source')

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
    seed: int = 42
    track: bool = False
    wandb_project: str | None = None
    wandb_entity: str | None = None
    data_dir: Path = Path("./experiment_results")


def main() -> None:
    args = tyro.cli(Args)

    experiment = Experiment(
        exp_name="LOGGING_TEST",
        seed=args.seed,
        data_dir=args.data_dir,
        env=MetaworldConfig(
            env_id="MT1",
            task_name="reach-v3",
            terminate_on_success=False,
        ),
        algorithm=SACConfig(
            num_tasks=1,
            gamma=0.99,
            actor_config=ContinuousActionPolicyConfig(
                network_config=VanillaNetworkConfig(
                    width=256,  # Smaller for faster testing
                    optimizer=OptimizerConfig(max_grad_norm=1.0)
                )
            ),
            critic_config=QValueFunctionConfig(
                network_config=VanillaNetworkConfig(
                    width=256,  # Smaller for faster testing
                    optimizer=OptimizerConfig(max_grad_norm=1.0)
                )
            ),
            num_critics=2,
        ),
        training_config=OffPolicyTrainingConfig(
            evaluation_frequency=50,  # Evaluate every 50 episodes
            total_steps=int(100_000),  # Short run
            buffer_size=int(10_000),
            batch_size=128,
        ),
        checkpoint=False,  # No checkpointing for quick test
        resume=False,
    )

    if args.track:
        experiment.enable_wandb(
            project=args.wandb_project,
            entity=args.wandb_entity,
            config=experiment,
            tags=["logging-test", "debug"],
        )

    experiment.run()


if __name__ == "__main__":
    main()
