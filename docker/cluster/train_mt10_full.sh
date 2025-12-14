#!/bin/bash
# SLURM job script for full MTRL MT10 training
# Full job: 20M steps (~8-12 hours on A40)

#SBATCH --job-name=mtrl_mt10_full
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gpus-per-node=1
#SBATCH --cpus-per-gpu=8
#SBATCH --mem=48G
#SBATCH --time=24:00:00
#SBATCH --partition=GPU-a40
#SBATCH --output=logs/slurm_%j.log
#SBATCH --error=logs/slurm_%j.err

set -e

# Configuration
CLUSTER_USER="${SLURM_SUBMIT_DIR##*/metaworld_project/}"
PROJECT_DIR="${HOME}/mtrl_project"
WORK_DIR="/share/${CLUSTER_USER}/mtrl_work/${SLURM_JOB_ID}"
SINGULARITY_IMAGE="${HOME}/mtrl.sif"
EXPERIMENT_NAME="mt10_full_${SLURM_JOB_ID}"

# Create directories
mkdir -p "$WORK_DIR"
mkdir -p "${PROJECT_DIR}/logs"
mkdir -p "${PROJECT_DIR}/models"

echo "=========================================="
echo "MTRL Full MT10 Training Started"
echo "=========================================="
echo "Job ID:       $SLURM_JOB_ID"
echo "GPU:          $CUDA_VISIBLE_DEVICES"
echo "Experiment:   $EXPERIMENT_NAME"
echo "=========================================="
echo ""

# Export environment
export APPTAINER_TMPDIR="$WORK_DIR"
export PYTHONUNBUFFERED=1
export WANDB_CACHE_DIR="${PROJECT_DIR}/wandb_cache"

# Run full training
apptainer exec \
    --nv \
    --bind "${PROJECT_DIR}/logs:/workspace/logs" \
    --bind "${PROJECT_DIR}/models:/workspace/models" \
    --bind "${PROJECT_DIR}/wandb_cache:/workspace/wandb_cache" \
    --bind "${PROJECT_DIR}/source/mtrl:/workspace/mtrl:ro" \
    --env "PYTHONUNBUFFERED=1" \
    --env "MUJOCO_GL=osmesa" \
    --env "WANDB_MODE=online" \
    "$SINGULARITY_IMAGE" \
    python experiments/mt10_mtmhsac.py \
        --experiment-name "$EXPERIMENT_NAME" \
        --seed 1 \
        --track

echo ""
echo "✅ Training completed! Results in ${PROJECT_DIR}/models/${EXPERIMENT_NAME}/"
