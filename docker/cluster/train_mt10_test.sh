#!/bin/bash
# SLURM job script for MTRL training on DataLAB cluster
# Test job: 100k steps (~15-20 minutes)

#SBATCH --job-name=mtrl_mt10_test
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gpus-per-node=1
#SBATCH --cpus-per-gpu=8
#SBATCH --mem=32G
#SBATCH --time=01:00:00
#SBATCH --partition=GPU-a40
#SBATCH --output=logs/slurm_%j.log
#SBATCH --error=logs/slurm_%j.err

set -e

# Configuration
CLUSTER_USER="${SLURM_SUBMIT_DIR##*/metaworld_project/}"
PROJECT_DIR="${HOME}/mtrl_project"
WORK_DIR="/share/${CLUSTER_USER}/mtrl_work/${SLURM_JOB_ID}"
SINGULARITY_IMAGE="${HOME}/mtrl.sif"

# Create directories
mkdir -p "$WORK_DIR"
mkdir -p "${PROJECT_DIR}/logs"
mkdir -p "${PROJECT_DIR}/models"

echo "=========================================="
echo "MTRL Training Job Started"
echo "=========================================="
echo "Job ID:       $SLURM_JOB_ID"
echo "Node:         $SLURM_NODEID"
echo "GPU:          $CUDA_VISIBLE_DEVICES"
echo "User:         $CLUSTER_USER"
echo "Work Dir:     $WORK_DIR"
echo "Project:      $PROJECT_DIR"
echo "=========================================="
echo ""

# Export environment
export APPTAINER_TMPDIR="$WORK_DIR"
export PYTHONUNBUFFERED=1
export WANDB_CACHE_DIR="${PROJECT_DIR}/wandb_cache"

# Validate Singularity image
if [ ! -f "$SINGULARITY_IMAGE" ]; then
    echo "❌ Error: Singularity image not found at $SINGULARITY_IMAGE"
    exit 1
fi

# Run training
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
        --experiment-name "mt10_test_${SLURM_JOB_ID}" \
        --seed 1 \
        --track

echo ""
echo "=========================================="
echo "Job completed successfully!"
echo "=========================================="
