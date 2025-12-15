#!/bin/bash
# MT10 Smoke Test (2M steps) - Single A40
# Purpose: validate logging, checkpoints, W&B before long runs

#SBATCH --job-name=mt10_smoke_2m
#SBATCH --partition=GPU-a40
#SBATCH --gres=gpu:a40:1
#SBATCH --cpus-per-task=12
#SBATCH --mem=48G
#SBATCH --time=12:00:00
#SBATCH --output=/home/e11704784/metaworld_project/logs/mt10_smoke_2m_%j.log
#SBATCH --error=/home/e11704784/metaworld_project/logs/mt10_smoke_2m_%j.err

set -e

PROJECT_DIR="/home/e11704784/metaworld_project"
SOURCE_DIR="${PROJECT_DIR}/source/mtrl"
CONTAINER="/share/e11704784/containers/mtrl.sif"
WANDB_CACHE="${PROJECT_DIR}/wandb_cache"
RESULTS_DIR="${PROJECT_DIR}/results/mt10_smoke_2m_${SLURM_JOB_ID}"

# W&B key
WANDB_KEY_FILE="/home/e11704784/.wandb_api_key"
if [ -f "$WANDB_KEY_FILE" ]; then
    WANDB_API_KEY=$(cat "$WANDB_KEY_FILE")
    WANDB_MODE="online"
else
    WANDB_MODE="offline"
    WANDB_API_KEY=""
fi

RUN_NAME="mt10_smoke_2m_${SLURM_JOB_ID}"
SEED=1
WANDB_PROJECT="mtrl-smoke"
WANDB_ENTITY="Robot_learning_2025"
TOTAL_STEPS=2000000  # 2M steps
BATCH_SIZE=640       # smaller for quicker turnaround
BUFFER_SIZE=200000   # smaller buffer for test

mkdir -p "${PROJECT_DIR}/logs" "$WANDB_CACHE"

if [ ! -f "$CONTAINER" ]; then
    echo "❌ Container not found: $CONTAINER"; exit 1; fi

echo "=========================================="
echo "MT10 Smoke Test (2M steps)"
echo "Job ID: $SLURM_JOB_ID"
echo "Run Name: $RUN_NAME"
echo "Seed: $SEED"
echo "W&B Mode: $WANDB_MODE"
echo "=========================================="

echo ""
nvidia-smi --query-gpu=gpu_name,memory.total --format=csv,noheader
echo ""

START_TIME=$(date +%s)

export SINGULARITYENV_WANDB_API_KEY="$WANDB_API_KEY"
export SINGULARITYENV_WANDB_MODE="$WANDB_MODE"
export SINGULARITYENV_WANDB_PROJECT="$WANDB_PROJECT"
export SINGULARITYENV_WANDB_ENTITY="$WANDB_ENTITY"
export SINGULARITYENV_WANDB_NAME="$RUN_NAME"
export SINGULARITYENV_WANDB_DIR="$WANDB_CACHE"
export SINGULARITYENV_XLA_PYTHON_CLIENT_PREALLOCATE="false"
export SINGULARITYENV_XLA_PYTHON_CLIENT_MEM_FRACTION="0.9"
export SINGULARITYENV_PYTHONPATH="/source:${SINGULARITYENV_PYTHONPATH}"

# Build a small smoke-test config (2M steps, smaller buffer/batch) to avoid editing the main experiment file
TMP_CONFIG="/tmp/mt10_smoke_${SLURM_JOB_ID}.py"
cat > "$TMP_CONFIG" << 'EOF'
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
    track: bool = True
    wandb_project: str = "mtrl-smoke"
    wandb_entity: str = "Robot_learning_2025"
    data_dir: Path = Path("/workspace/results/mt10_smoke_2m")
    resume: bool = False


def main() -> None:
    args = tyro.cli(Args)

    experiment = Experiment(
        exp_name="mt10_smoke_2m",
        seed=args.seed,
        data_dir=args.data_dir,
        env=MetaworldConfig(env_id="MT10", terminate_on_success=False),
        algorithm=MTSACConfig(
            num_tasks=10,
            gamma=0.99,
            actor_config=ContinuousActionPolicyConfig(
                network_config=MultiHeadConfig(num_tasks=10, optimizer=OptimizerConfig(max_grad_norm=1.0))
            ),
            critic_config=QValueFunctionConfig(
                network_config=MultiHeadConfig(num_tasks=10, optimizer=OptimizerConfig(max_grad_norm=1.0)),
            ),
            num_critics=2,
        ),
        training_config=OffPolicyTrainingConfig(
            total_steps=2_000_000,  # 2M steps for smoke test
            buffer_size=200_000,
            batch_size=640,
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
EOF

# Run the smoke config (2M steps)
singularity exec --nv \
    --bind "${PROJECT_DIR}:/workspace,${SOURCE_DIR}:/source,/tmp:/tmp" \
    --pwd /source \
    "${CONTAINER}" \
    python "$TMP_CONFIG" \
        --seed "${SEED}" \
        --track \
        --wandb-project "${WANDB_PROJECT}" \
        --wandb-entity "${WANDB_ENTITY}" \
        --data-dir "/workspace/results/${RUN_NAME}"

EXIT_CODE=$?

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
HOURS=$((ELAPSED / 3600))
MINUTES=$(((ELAPSED % 3600) / 60))
SECONDS=$((ELAPSED % 60))

echo ""
echo "=========================================="
echo "SMOKE TEST COMPLETED"
echo "=========================================="
echo "Exit Code: $EXIT_CODE"
echo "Elapsed: ${HOURS}h ${MINUTES}m ${SECONDS}s"
echo "=========================================="

if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ SUCCESS: Check W&B: https://wandb.ai/${WANDB_ENTITY}/${WANDB_PROJECT}"
    echo "Logs: ${PROJECT_DIR}/logs/mt10_smoke_2m_${SLURM_JOB_ID}.log"
else
    echo "❌ FAILED: See logs: ${PROJECT_DIR}/logs/mt10_smoke_2m_${SLURM_JOB_ID}.log"
fi

exit $EXIT_CODE
