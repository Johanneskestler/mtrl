#!/bin/bash
# SBATCH Script: MT10 Multi-Task SAC Training (Paper Parameters)
# GPU: A100 (80GB)
# Steps: 20M timesteps
# Logging: W&B + periodic checkpoints
# Paper: McLean et al., 2025 - Multi-Task RL Enables Parameter Scaling

#SBATCH --job-name=mt10_sac_20m
#SBATCH --partition=GPU-a100
#SBATCH --gres=gpu:a100:1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=48:00:00
#SBATCH --output=/home/e11704784/metaworld_project/logs/mt10_sac_20m_%j.log
#SBATCH --error=/home/e11704784/metaworld_project/logs/mt10_sac_20m_%j.err

set -e

# ============================================================================
# Environment Configuration
# ============================================================================
PROJECT_DIR="/home/e11704784/metaworld_project"
SOURCE_DIR="${PROJECT_DIR}/source/mtrl"
CONTAINER="/share/e11704784/containers/mtrl.sif"
LOG_DIR="${PROJECT_DIR}/logs"
MODEL_DIR="${PROJECT_DIR}/models/mt10_sac_${SLURM_JOB_ID}"
WANDB_CACHE="${PROJECT_DIR}/wandb_cache"
RESULTS_DIR="${PROJECT_DIR}/results/mt10_sac_${SLURM_JOB_ID}"

# Ensure WANDB_API_KEY is set (either via --export or default)
if [ -z "$WANDB_API_KEY" ]; then
    echo "⚠️  Warning: WANDB_API_KEY not set. W&B logging will be disabled."
    echo "   Set via: sbatch --export=WANDB_API_KEY=<your-key> train_mt10_a100_20m.sh"
    WANDB_MODE="offline"
else
    WANDB_MODE="online"
fi

# ============================================================================
# Paper Parameters - MT10 SAC Baseline
# ============================================================================
# Reference: McLean et al., 2025, Table 1 & Appendix
TOTAL_STEPS=20000000        # 20M total steps (2M per task)
SEED=${SLURM_ARRAY_TASK_ID:-1}  # Use array task ID as seed, default 1

# Training hyperparameters (from paper)
BATCH_SIZE=1280             # Paper: 1280 for MT10
BUFFER_SIZE=1000000         # 1M replay buffer
GAMMA=0.99                  # Discount factor
NUM_CRITICS=2               # Twin Q-networks

# Network architecture (paper baseline: 3 layers, 1024 width)
HIDDEN_LAYERS=3
HIDDEN_WIDTH=1024

# W&B Configuration
WANDB_PROJECT="mtrl-mt10"
WANDB_ENTITY="${SLURM_JOB_USER}"
WANDB_RUN_NAME="MT10_SAC_20M_seed${SEED}_job${SLURM_JOB_ID}"

# ============================================================================
# Job Info
# ============================================================================
echo "=========================================="
echo "MT10 Multi-Task SAC Training (20M Steps)"
echo "=========================================="
echo "SLURM Job ID: $SLURM_JOB_ID"
echo "Node: $SLURM_NODELIST"
echo "Start Time: $(date)"
echo "=========================================="
echo ""
echo "TRAINING CONFIGURATION:"
echo "  Algorithm:      Multi-Task SAC (MTSAC)"
echo "  Environment:    MetaWorld MT10 (10 tasks)"
echo "  Total Steps:    ${TOTAL_STEPS} (20M)"
echo "  Seed:           $SEED"
echo "  Batch Size:     $BATCH_SIZE"
echo "  Buffer Size:    $BUFFER_SIZE"
echo "  Gamma:          $GAMMA"
echo "  Network:        ${HIDDEN_LAYERS}x${HIDDEN_WIDTH} (multi-head)"
echo "  Critics:        $NUM_CRITICS (twin Q)"
echo ""
echo "LOGGING & CHECKPOINTS:"
echo "  W&B Project:    $WANDB_PROJECT"
echo "  W&B Mode:       $WANDB_MODE"
echo "  Model Dir:      $MODEL_DIR"
echo "  Results Dir:    $RESULTS_DIR"
echo "  Checkpoint:     Every 1M steps (auto-managed)"
echo "=========================================="
echo ""

# ============================================================================
# Setup
# ============================================================================
mkdir -p "$LOG_DIR" "$MODEL_DIR" "$WANDB_CACHE" "$RESULTS_DIR"

# Verify container exists
if [ ! -f "$CONTAINER" ]; then
    echo "❌ Error: Container not found at $CONTAINER"
    echo "   Expected: /share/${SLURM_JOB_USER}/containers/mtrl.sif"
    exit 1
fi

echo "✅ Container found: $CONTAINER ($(du -h "$CONTAINER" | cut -f1))"

# Verify source code
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ Error: Source directory not found at $SOURCE_DIR"
    exit 1
fi

echo "✅ Source code found: $SOURCE_DIR"

# GPU Check
echo ""
nvidia-smi --query-gpu=gpu_name,memory.total,driver_version --format=csv,noheader
echo ""

# Start timing
START_TIME=$(date +%s)

# ============================================================================
# Run Training via Singularity
# ============================================================================
echo "🚀 Starting MT10 Training (20M timesteps)..."
echo ""

# Set environment variables for container
export SINGULARITYENV_WANDB_API_KEY="$WANDB_API_KEY"
export SINGULARITYENV_WANDB_MODE="$WANDB_MODE"
export SINGULARITYENV_WANDB_PROJECT="$WANDB_PROJECT"
export SINGULARITYENV_WANDB_ENTITY="$WANDB_ENTITY"
export SINGULARITYENV_WANDB_NAME="$WANDB_RUN_NAME"
export SINGULARITYENV_WANDB_DIR="$WANDB_CACHE"
export SINGULARITYENV_XLA_PYTHON_CLIENT_PREALLOCATE="false"
export SINGULARITYENV_XLA_PYTHON_CLIENT_MEM_FRACTION="0.9"

# Run training with paper parameters
singularity exec --nv \
    --bind "${PROJECT_DIR}:/workspace,${SOURCE_DIR}:/source" \
    --pwd /source \
    "${CONTAINER}" \
    python experiments/mt10_mtmhsac.py \
        --seed "${SEED}" \
        --track \
        --wandb-project "${WANDB_PROJECT}" \
        --wandb-entity "${WANDB_ENTITY}" \
        --data-dir "/workspace/results/mt10_sac_${SLURM_JOB_ID}"

TRAIN_EXIT_CODE=$?

# End timing
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
HOURS=$((ELAPSED / 3600))
MINUTES=$(((ELAPSED % 3600) / 60))
SECONDS=$((ELAPSED % 60))

# ============================================================================
# Post-Training Summary
# ============================================================================
echo ""
echo "=========================================="
echo "TRAINING COMPLETED"
echo "=========================================="
echo "Exit Code: $TRAIN_EXIT_CODE"
echo "End Time: $(date)"
echo "Elapsed Time: ${HOURS}h ${MINUTES}m ${SECONDS}s"
echo "=========================================="

# GPU summary
echo ""
echo "Final GPU Status:"
nvidia-smi --query-gpu=utilization.gpu,utilization.memory,memory.used,memory.total --format=csv,noheader

if [ $TRAIN_EXIT_CODE -eq 0 ]; then
    echo ""
    echo "✅ SUCCESS: MT10 Training completed!"
    echo "📊 Check W&B: https://wandb.ai/${WANDB_ENTITY}/${WANDB_PROJECT}"
    echo "💾 Checkpoints: ${RESULTS_DIR}/checkpoints/"
    echo "📋 Logs: ${LOG_DIR}/mt10_sac_20m_${SLURM_JOB_ID}.log"
    echo ""
    if [ -d "${RESULTS_DIR}/checkpoints" ]; then
        echo "Checkpoint summary:"
        ls -lh "${RESULTS_DIR}/checkpoints/" | tail -5
    fi
else
    echo ""
    echo "❌ ERROR: Training failed with exit code $TRAIN_EXIT_CODE"
    echo "📋 Check logs: ${LOG_DIR}/mt10_sac_20m_${SLURM_JOB_ID}.log"
fi

exit $TRAIN_EXIT_CODE
