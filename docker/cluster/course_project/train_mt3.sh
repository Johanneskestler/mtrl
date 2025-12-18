#!/bin/bash
# SLURM job script for Multi-Task MTMHSAC training: MT3 (reach+push+pick-place)
# Course Project: From Single-Task to Multi-Task RL
# Expected average success rate: > 40%

#SBATCH --job-name=MT3_MTMHSAC
#SBATCH --partition=GPU-l40s
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=04:00:00
#SBATCH --output=/home/e11704784/metaworld_project/logs/mt3_%j.log
#SBATCH --error=/home/e11704784/metaworld_project/logs/mt3_%j.err

set -e

PROJECT_DIR="/home/e11704784/metaworld_project"
SOURCE_DIR="${PROJECT_DIR}/source"
CONTAINER="/share/e11704784/containers/mtrl.sif"
WANDB_CACHE="${PROJECT_DIR}/wandb_cache"
RESULTS_DIR="${PROJECT_DIR}/results/mt3_${SLURM_JOB_ID}"
SEED="${SEED:-1}"

mkdir -p "${PROJECT_DIR}/logs" "$WANDB_CACHE"

if [ ! -f "$CONTAINER" ]; then
    echo "❌ Container not found: $CONTAINER"; exit 1; fi

echo "=========================================="
echo "Multi-Task MTMHSAC Training: MT3"
echo "Job ID: $SLURM_JOB_ID"
echo "Seed: $SEED"
echo "Tasks: reach, push, pick-place"
echo "=========================================="
echo ""
nvidia-smi --query-gpu=gpu_name,memory.total --format=csv,noheader
echo ""

export SINGULARITYENV_PYTHONPATH="/source"
export SINGULARITYENV_PYTHONDONTWRITEBYTECODE="1"
export SINGULARITYENV_WANDB_MODE="online"
export SINGULARITYENV_WANDB_DIR="$WANDB_CACHE"

singularity exec --nv \
    --bind "${PROJECT_DIR}:/workspace,${SOURCE_DIR}:/source" \
    --pwd /source \
    "${CONTAINER}" \
    python experiments/course_project/mt3_reach_push_pickplace.py \
        --seed "${SEED}" \
        --track \
        --wandb-project "Robot_learning_2025" \
        --wandb-entity "Robot_learning_2025" \
        --data-dir "/workspace/results/mt3_${SLURM_JOB_ID}"

EXIT_CODE=$?
echo ""
echo "=========================================="
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ MT3 training completed!"
else
    echo "❌ MT3 training failed!"
fi
echo "=========================================="
exit $EXIT_CODE
