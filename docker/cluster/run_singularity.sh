#!/bin/bash
# Universal Singularity runner for MTRL cluster jobs
# Handles mounts, environment variables, and argument passing

set -e

# Configuration from environment or defaults
CLUSTER_USER="${CLUSTER_USER:-e11704784}"
WORK_DIR="${WORK_DIR:-/share/${CLUSTER_USER}/mtrl_work}"
SINGULARITY_IMAGE="${SINGULARITY_IMAGE:-${HOME}/mtrl.sif}"
PROJECT_DIR="${PROJECT_DIR:-${HOME}/mtrl_project}"

# Create work directory if needed
mkdir -p "$WORK_DIR"
mkdir -p "${PROJECT_DIR}/logs"
mkdir -p "${PROJECT_DIR}/models"
mkdir -p "${PROJECT_DIR}/wandb_cache"

# Prepare argument string (properly quoted for shell)
ARGS=""
for arg in "$@"; do
    ARGS="${ARGS} $(printf '%q' "$arg")"
done

echo "=========================================="
echo "Running MTRL in Singularity"
echo "=========================================="
echo "Image:        $SINGULARITY_IMAGE"
echo "Work dir:     $WORK_DIR"
echo "Project:      $PROJECT_DIR"
echo "Command:      python${ARGS}"
echo "=========================================="
echo ""

# Set environment variables for cluster
export APPTAINER_TMPDIR="$WORK_DIR"
export PYTHONUNBUFFERED=1
export OMP_NUM_THREADS=8

# Run Singularity with mounts
apptainer exec \
    --nv \
    --bind "${PROJECT_DIR}/logs:/workspace/logs" \
    --bind "${PROJECT_DIR}/models:/workspace/models" \
    --bind "${PROJECT_DIR}/wandb_cache:/workspace/wandb_cache" \
    --bind "${PROJECT_DIR}/source:/workspace/mtrl:ro" \
    --env "PYTHONUNBUFFERED=1" \
    --env "MUJOCO_GL=osmesa" \
    --env "CUDA_VISIBLE_DEVICES=0" \
    "$SINGULARITY_IMAGE" \
    python $ARGS

exit $?
