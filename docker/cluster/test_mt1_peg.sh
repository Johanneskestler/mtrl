#!/bin/bash
# Test Original MT1 Script

#SBATCH --job-name=test_mt1_peg
#SBATCH --partition=GPU-l40s
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=00:30:00
#SBATCH --output=/home/e11704784/metaworld_project/logs/test_mt1_peg_%j.log
#SBATCH --error=/home/e11704784/metaworld_project/logs/test_mt1_peg_%j.err

set -e

PROJECT_DIR="/home/e11704784/metaworld_project"
SOURCE_DIR="${PROJECT_DIR}/source/mtrl"
CONTAINER="/share/e11704784/containers/mtrl.sif"
WANDB_CACHE="${PROJECT_DIR}/wandb_cache"
SEED="${SEED:-1}"

mkdir -p "${PROJECT_DIR}/logs" "$WANDB_CACHE"

if [ ! -f "$CONTAINER" ]; then
    echo "❌ Container not found: $CONTAINER"; exit 1; fi

echo "=========================================="
echo "Testing Original MT1 Peg Insert Side"
echo "Job ID: $SLURM_JOB_ID"
echo "Seed: $SEED"
echo "=========================================="
echo ""
nvidia-smi --query-gpu=gpu_name,memory.total --format=csv,noheader
echo ""

export SINGULARITYENV_PYTHONPATH="/source:${SINGULARITYENV_PYTHONPATH}"
export SINGULARITYENV_WANDB_MODE="online"
export SINGULARITYENV_WANDB_DIR="$WANDB_CACHE"

singularity exec --nv \
    --bind "${PROJECT_DIR}:/workspace,${SOURCE_DIR}:/source" \
    --pwd /source \
    "${CONTAINER}" \
    python experiments/single_task/mt1_peg_insert_side.py \
        --seed "${SEED}" \
        --track \
        --wandb-project "mtrl-test" \
        --wandb-entity "Robot_learning_2025" \
        --data-dir "/workspace/results/test_peg_${SLURM_JOB_ID}"

EXIT_CODE=$?
echo ""
echo "=========================================="
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Test erfolgreich!"
else
    echo "❌ Test fehlgeschlagen!"
fi
echo "=========================================="
exit $EXIT_CODE
