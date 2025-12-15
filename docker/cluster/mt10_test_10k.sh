#!/bin/bash
# MT10 Quick Test (10k steps, ~5 minutes)
# Use this to verify setup before long runs

#SBATCH --job-name=mt10_test
#SBATCH --partition=GPU-a40
#SBATCH --gres=gpu:a40:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=00:30:00
#SBATCH --output=/home/e11704784/metaworld_project/logs/mt10_test_%j.log
#SBATCH --error=/home/e11704784/metaworld_project/logs/mt10_test_%j.err

set -e

PROJECT_DIR="/home/e11704784/metaworld_project"
SOURCE_DIR="${PROJECT_DIR}/source/mtrl"
CONTAINER="/share/e11704784/containers/mtrl.sif"
WANDB_CACHE="${PROJECT_DIR}/wandb_cache"

# Load W&B API key
WANDB_KEY_FILE="/home/e11704784/.wandb_api_key"
if [ -f "$WANDB_KEY_FILE" ]; then
    WANDB_API_KEY=$(cat "$WANDB_KEY_FILE")
    WANDB_MODE="online"
else
    WANDB_MODE="offline"
    WANDB_API_KEY=""
fi

RUN_NAME="mt10_test_10k"
SEED=42
WANDB_PROJECT="mtrl-test"
WANDB_ENTITY="Robot_learning_2025"

echo "=========================================="
echo "MT10 Quick Test (10k steps)"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Start: $(date)"
echo "W&B Mode: $WANDB_MODE"
echo "=========================================="

mkdir -p "${PROJECT_DIR}/logs" "$WANDB_CACHE"

if [ ! -f "$CONTAINER" ]; then
    echo "❌ Container not found: $CONTAINER"
    exit 1
fi

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

# Create test config with 10k steps
TEST_CONFIG="/tmp/test_mt10_${SLURM_JOB_ID}.py"
cat > "$TEST_CONFIG" << 'EOF'
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
    track: bool = True
    wandb_project: str = "mtrl-test"
    wandb_entity: str = "Robot_learning_2025"
    data_dir: Path = Path("/workspace/results/mt10_test_10k")
    resume: bool = False

def main() -> None:
    args = tyro.cli(Args)
    experiment = Experiment(
        exp_name="mt10_test_10k",
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
            total_steps=10000,  # 10k test
            buffer_size=10000,
            batch_size=128,
        ),
        checkpoint=False,
        resume=args.resume,
    )
    if args.track:
        experiment.enable_wandb(project=args.wandb_project, entity=args.wandb_entity, config=experiment, resume="allow")
    experiment.run()

if __name__ == "__main__":
    main()
EOF

singularity exec --nv \
    --bind "${PROJECT_DIR}:/workspace,${SOURCE_DIR}:/source,${TEST_CONFIG}:/tmp/test_config.py" \
    --pwd /source \
    "${CONTAINER}" \
    python /tmp/test_config.py

EXIT_CODE=$?

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS=$((ELAPSED % 60))

echo ""
echo "=========================================="
echo "TEST COMPLETED"
echo "=========================================="
echo "Exit Code: $EXIT_CODE"
echo "Elapsed: ${MINUTES}m ${SECONDS}s"
echo "=========================================="

if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Test passed! Ready for full training."
else
    echo "❌ Test failed. Check logs before submitting long runs."
fi

exit $EXIT_CODE
