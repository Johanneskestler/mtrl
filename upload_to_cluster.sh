#!/bin/bash
# Upload MTRL Singularity Container und Code zum DataLAB Cluster
# Usage: ./upload_to_cluster.sh

set -e

CLUSTER_USER="e11704784"
CLUSTER_HOST="cluster.datalab.tuwien.ac.at"
LOCAL_SIF="/tmp/mtrl.sif"
# Set this to your local repo root (anpassen falls nötig!)
LOCAL_REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "=========================================="
echo "MTRL Cluster Upload"
echo "=========================================="
echo ""

# 1. Upload SIF to cluster (if exists)
if [ -f "$LOCAL_SIF" ]; then
    SIF_SIZE=$(du -h "$LOCAL_SIF" | cut -f1)
    echo "✅ Found SIF: $LOCAL_SIF ($SIF_SIZE)"
    echo ""
    echo "📤 Uploading container to cluster..."
    echo "   This will take ~30-40 minutes for 6.6GB..."
    echo ""
    rsync -avz --progress "$LOCAL_SIF" \
        "${CLUSTER_USER}@${CLUSTER_HOST}:/share/${CLUSTER_USER}/containers/"
    echo ""
    echo "✅ Container uploaded!"
    echo ""
else
    echo "ℹ️  No SIF found at $LOCAL_SIF, skipping container upload."
    echo ""
fi

# 2. Upload code (entire repo root, excluding SIF and unwanted files)
echo "📤 Uploading code to cluster..."
echo ""

rsync -avz --progress \
    --exclude='.git' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='.vscode' \
    --exclude='experiment_results' \
    --exclude='wandb' \
    --exclude='.pytest_cache' \
    --exclude='*.sif' \
    "$LOCAL_REPO_ROOT/" \
    "${CLUSTER_USER}@${CLUSTER_HOST}:~/metaworld_project/source/"

echo ""
echo "✅ Code uploaded!"
echo ""

# 3. Setup directories on cluster
echo "📁 Setting up directories on cluster..."
ssh "${CLUSTER_USER}@${CLUSTER_HOST}" "mkdir -p ~/metaworld_project/{logs,wandb_cache,results}"

echo ""
echo "=========================================="
echo "✅ Upload complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. SSH to cluster:  ssh ${CLUSTER_USER}@${CLUSTER_HOST}"
echo "  2. Go to scripts:   cd ~/metaworld_project/source/docker/cluster/course_project"
echo "  3. Submit jobs:     ./submit_all.sh 42"
echo ""
echo "Monitor jobs:"
echo "  squeue -u ${CLUSTER_USER}"
echo "  tail -f ~/metaworld_project/logs/*.log"
echo ""
echo "WandB: https://wandb.ai/Robot_learning_2025/Robot_learning_2025"
echo "=========================================="