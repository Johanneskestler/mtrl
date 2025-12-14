"""Enhanced W&B Integration for MTRL Experiments

Provides comprehensive logging of:
- Training metrics (loss, rewards, success rates)
- Network architecture details
- Hyperparameter configurations
- Task-specific performance
- Hardware monitoring (GPU, memory)
"""

import time
import json
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Any, Dict, Optional

import numpy as np
import wandb


@dataclass
class WandBConfig:
    """W&B Configuration for MTRL experiments"""
    
    project: str = "Robot_learning_2025"
    entity: str = "Robot_learning_2025"
    mode: str = "online"  # "online", "offline", "disabled"
    
    # Experiment tracking
    tags: list = None
    notes: str = ""
    
    # Logging frequency
    log_frequency: int = 100  # Log every N steps
    
    # What to log
    log_gradients: bool = True
    log_network_stats: bool = True
    log_task_performance: bool = True
    log_system_stats: bool = True
    
    def __post_init__(self):
        if self.tags is None:
            self.tags = []


class MtrlWandBLogger:
    """Enhanced W&B logging for MTRL"""
    
    def __init__(
        self,
        config: WandBConfig,
        experiment_config: Dict[str, Any],
        run_name: str,
        run_id: Optional[str] = None,
    ):
        """Initialize W&B logger
        
        Args:
            config: WandB configuration
            experiment_config: Full experiment configuration dict
            run_name: Name of the run
            run_id: Optional run ID for resuming
        """
        self.config = config
        self.experiment_config = experiment_config
        self.run_name = run_name
        self.run_id = run_id
        self.step = 0
        
        # Initialize W&B
        self._init_wandb()
        
    def _init_wandb(self):
        """Initialize wandb with enhanced config"""
        
        # Prepare tags
        tags = list(self.config.tags) if self.config.tags else []
        if "mt10" in self.run_name.lower():
            tags.append("MT10")
        elif "mt50" in self.run_name.lower():
            tags.append("MT50")
        
        # Initialize run
        self.run = wandb.init(
            project=self.config.project,
            entity=self.config.entity,
            name=self.run_name,
            id=self.run_id,
            config=self.experiment_config,
            tags=tags,
            notes=self.config.notes,
            mode=self.config.mode,
            resume="allow" if self.run_id else None,
            # Advanced settings
            save_code=True,
            config_exclude_keys=["data_dir"],  # Don't log data paths
        )
        
        # Log system info
        wandb.run.log_code()
        
        # Log full config as artifact (for reproducibility)
        self._log_config_artifact()
        
    def _log_config_artifact(self):
        """Save full config as artifact"""
        config_path = Path(wandb.run.dir) / "config.json"
        with open(config_path, "w") as f:
            json.dump(self.experiment_config, f, indent=2, default=str)
        
        artifact = wandb.Artifact("experiment_config", type="config")
        artifact.add_file(config_path)
        self.run.log_artifact(artifact)
        
    def log_training_metrics(
        self,
        step: int,
        metrics: Dict[str, float],
        log_freq: Optional[int] = None,
    ) -> None:
        """Log training metrics
        
        Args:
            step: Training step number
            metrics: Dict of metric_name -> value
            log_freq: Override log frequency for this call
        """
        self.step = step
        
        # Check if should log
        freq = log_freq or self.config.log_frequency
        if step % freq != 0:
            return
        
        # Add timing info
        if not hasattr(self, "_last_log_time"):
            self._last_log_time = time.time()
            elapsed = 0
        else:
            elapsed = time.time() - self._last_log_time
            self._last_log_time = time.time()
        
        # Log metrics with step
        log_dict = {
            **metrics,
            "training_step": step,
            "elapsed_time_s": elapsed,
        }
        
        wandb.log(log_dict, step=step)
        
    def log_task_performance(
        self,
        task_name: str,
        task_id: int,
        episode_return: float,
        success_rate: float,
        episode_length: int,
    ) -> None:
        """Log per-task performance metrics
        
        Args:
            task_name: Name of the task
            task_id: Task ID number
            episode_return: Total return from episode
            success_rate: Success rate for task
            episode_length: Episode length
        """
        wandb.log({
            f"task/{task_name}/return": episode_return,
            f"task/{task_name}/success_rate": success_rate,
            f"task/{task_name}/episode_length": episode_length,
            f"task_id_{task_id}/return": episode_return,
        }, step=self.step)
        
    def log_network_architecture(self, architecture_dict: Dict[str, Any]) -> None:
        """Log network architecture details"""
        if not self.config.log_network_stats:
            return
        
        # Count parameters
        param_counts = architecture_dict.get("parameter_counts", {})
        
        summary = {
            "architecture": architecture_dict,
            "total_parameters": sum(param_counts.values()),
            **{f"params/{k}": v for k, v in param_counts.items()},
        }
        
        # Log as table
        table = wandb.Table(
            columns=["Component", "Parameters"],
            data=[[k, v] for k, v in param_counts.items()],
        )
        
        wandb.log({"network_architecture": table})
        
    def log_loss_curves(self, loss_history: Dict[str, list]) -> None:
        """Log loss curves as plots
        
        Args:
            loss_history: Dict mapping loss_name -> list of values
        """
        import matplotlib.pyplot as plt
        
        fig, axes = plt.subplots(1, len(loss_history), figsize=(15, 4))
        if len(loss_history) == 1:
            axes = [axes]
        
        for ax, (loss_name, values) in zip(axes, loss_history.items()):
            ax.plot(values)
            ax.set_title(loss_name)
            ax.set_xlabel("Steps")
            ax.set_ylabel("Loss")
            ax.grid(True)
        
        plt.tight_layout()
        wandb.log({"loss_curves": wandb.Image(fig)})
        plt.close(fig)
        
    def log_replay_buffer_stats(
        self,
        buffer_size: int,
        num_tasks: int,
        buffer_per_task: Dict[int, int],
    ) -> None:
        """Log replay buffer statistics"""
        wandb.log({
            "buffer/total_size": buffer_size,
            "buffer/num_tasks": num_tasks,
            "buffer/avg_per_task": buffer_size / num_tasks,
        })
        
        # Log per-task distribution
        for task_id, size in buffer_per_task.items():
            wandb.log({f"buffer/task_{task_id}": size})
            
    def log_gradient_stats(self, gradients: Dict[str, np.ndarray]) -> None:
        """Log gradient statistics for monitoring training
        
        Args:
            gradients: Dict mapping param_name -> gradient array
        """
        if not self.config.log_gradients:
            return
        
        for param_name, grad in gradients.items():
            if grad is not None:
                wandb.log({
                    f"gradients/{param_name}/mean": float(np.mean(np.abs(grad))),
                    f"gradients/{param_name}/std": float(np.std(grad)),
                    f"gradients/{param_name}/max": float(np.max(np.abs(grad))),
                })
                
    def log_system_metrics(
        self,
        gpu_memory_gb: float,
        gpu_utilization: float,
        cpu_utilization: float,
    ) -> None:
        """Log system resource metrics"""
        if not self.config.log_system_stats:
            return
        
        wandb.log({
            "system/gpu_memory_gb": gpu_memory_gb,
            "system/gpu_utilization": gpu_utilization,
            "system/cpu_utilization": cpu_utilization,
        })
        
    def log_checkpoint(
        self,
        checkpoint_path: Path,
        metrics: Dict[str, float],
    ) -> None:
        """Log checkpoint as artifact
        
        Args:
            checkpoint_path: Path to checkpoint file
            metrics: Associated metrics
        """
        artifact = wandb.Artifact(
            name=f"checkpoint_{self.step}",
            type="model",
            metadata=metrics,
        )
        artifact.add_file(str(checkpoint_path))
        self.run.log_artifact(artifact)
        
    def finish(self, summary_metrics: Optional[Dict[str, float]] = None) -> None:
        """Finish logging run
        
        Args:
            summary_metrics: Final summary metrics
        """
        if summary_metrics:
            for k, v in summary_metrics.items():
                self.run.summary[k] = v
        
        self.run.finish()
        
    def __enter__(self):
        return self
    
    def __exit__(self, *args):
        self.finish()


# Example usage in experiment
def setup_wandb_logging(
    exp_name: str,
    seed: int,
    config: Dict[str, Any],
    enable_tracking: bool = False,
) -> Optional[MtrlWandBLogger]:
    """Setup W&B logging for MTRL experiment
    
    Args:
        exp_name: Experiment name
        seed: Random seed
        config: Full experiment config
        enable_tracking: Whether to enable W&B tracking
        
    Returns:
        MtrlWandBLogger instance or None if disabled
    """
    if not enable_tracking:
        return None
    
    wandb_config = WandBConfig(
        mode="online",
        tags=["mtrl", f"seed_{seed}"],
        notes=f"Experiment: {exp_name}",
    )
    
    run_id = f"{exp_name}_{seed}_{int(time.time())}"
    
    logger = MtrlWandBLogger(
        config=wandb_config,
        experiment_config=config,
        run_name=exp_name,
        run_id=run_id,
    )
    
    return logger
