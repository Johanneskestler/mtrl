#!/bin/bash
# MT10 Paper Baseline (20M steps, seed 1)
# Paper: McLean et al., 2025 - Multi-Task RL Enables Parameter Scaling
# Network: 3x1024 multi-head SAC (baseline from paper)
# Hardware: A100 GPU, ~40-48h runtime

#SBATCH --job-name=mt10_baseline
#SBATCH --partition=GPU-a100
#SBATCH --gres=gpu:a100:1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=48:00:00
#SBATCH --output=/home/e11704784/metaworld_project/logs/mt10_baseline_seed1_%j.log
#SBATCH --error=/home/e11704784/metaworld_project/logs/mt10_baseline_seed1_%j.err

set -e

# ============================================================================
# Configuration
# ============================================================================
PROJECT_DIR="/home/e11704784/metaworld_project"
SOURCE_DIR="${PROJECT_DIR}/source/mtrl"
CONTAINER="/share/e11704784/containers/mtrl.sif"
RESULTS_DIR="${PROJECT_DIR}/results/mt10_baseline_seed1_${SLURM_JOB_ID}"
WANDB_CACHE="${PROJECT_DIR}/wandb_cache"

# Load W&B API key
WANDB_KEY_FILE="/home/e11704784/.wandb_api_key"
if [ -f "$WANDB_KEY_FILE" ]; then
    WANDB_API_KEY=$(cat "$WANDB_KEY_FILE")
    WANDB_MODE="online"
else
    echo "⚠️  W&B API key not found. Run: bash docker/cluster/setup_wandb_key.sh"
    WANDB_MODE="offline"
    WANDB_API_KEY=""
fi

# Experiment Configuration
RUN_NAME="mt10_baseline_seed1"
SEED=1
TOTAL_STEPS=20000000

# W&B
WANDB_PROJECT="mtrl-paper-baseline"
WANDB_ENTITY="Robot_learning_2025"

# ============================================================================
# Job Info
# ============================================================================
echo "=========================================="
echo "MT10 Paper Baseline (Seed 1)"
echo "=========================================="
echo "SLURM Job ID: $SLURM_JOB_ID"
echo "Node: $SLURM_NODELIST"
echo "Start Time: $(date)"
echo "=========================================="
echo ""
echo "Configuration:"
echo "  Run Name:    $RUN_NAME"
echo "  Total Steps: 20M"
echo "  Seed:        $SEED"
echo "  Network:     3x1024 multi-head (paper baseline)"
echo "  W&B Mode:    $WANDB_MODE"
echo "  W&B Project: $WANDB_PROJECT"
echo "=========================================="

# Create directories
mkdir -p "${PROJECT_DIR}/logs" "$WANDB_CACHE"

# Verify container
if [ ! -f "$CONTAINER" ]; then
    echo "❌ Container not found: $CONTAINER"
    exit 1
fi

# GPU Check
echo ""
nvidia-smi --query-gpu=gpu_name,memory.total,driver_version --format=csv,noheader
echo ""

# Start timing
START_TIME=$(date +%s)

# ============================================================================
# Run Training
# ============================================================================
echo "🚀 Starting training..."
echo ""

export SINGULARITYENV_WANDB_API_KEY="$WANDB_API_KEY"
export SINGULARITYENV_WANDB_MODE="$WANDB_MODE"
export SINGULARITYENV_WANDB_PROJECT="$WANDB_PROJECT"
export SINGULARITYENV_WANDB_ENTITY="$WANDB_ENTITY"
export SINGULARITYENV_WANDB_NAME="$RUN_NAME"
export SINGULARITYENV_WANDB_DIR="$WANDB_CACHE"
export SINGULARITYENV_XLA_PYTHON_CLIENT_PREALLOCATE="false"
export SINGULARITYENV_XLA_PYTHON_CLIENT_MEM_FRACTION="0.9"

singularity exec --nv \
    --bind "${PROJECT_DIR}:/workspace,${SOURCE_DIR}:/source" \
    --pwd /source \
    "${CONTAINER}" \
    python experiments/mt10_mtmhsac.py \
        --seed "${SEED}" \
        --track \
        --wandb-project "${WANDB_PROJECT}" \
        --wandb-entity "${WANDB_ENTITY}" \
        --data-dir "/workspace/results/${RUN_NAME}_${SLURM_JOB_ID}"

EXIT_CODE=$?

# End timing
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
HOURS=$((ELAPSED / 3600))
MINUTES=$(((ELAPSED % 3600) / 60))
SECONDS=$((ELAPSED % 60))

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "=========================================="
echo "TRAINING COMPLETED"
echo "=========================================="
echo "Exit Code: $EXIT_CODE"
echo "End Time: $(date)"
echo "Elapsed: ${HOURS}h ${MINUTES}m ${SECONDS}s"
echo "=========================================="

echo ""
echo "Final GPU Status:"
nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "✅ SUCCESS: Training completed!"
    echo "📊 W&B: https://wandb.ai/${WANDB_ENTITY}/${WANDB_PROJECT}/runs/${RUN_NAME}"
    echo "💾 Checkpoints: ${RESULTS_DIR}/checkpoints/"
else
    echo ""
    echo "❌ FAILED: Exit code $EXIT_CODE"
    echo "📋 Check logs: ${PROJECT_DIR}/logs/mt10_baseline_seed1_${SLURM_JOB_ID}.log"
fi

exit $EXIT_CODE
