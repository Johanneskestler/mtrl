#!/bin/bash
# Quick deployment script for Course Project
# Usage: ./deploy_to_datalab.sh [seed]

set -e

CLUSTER_HOST="datalab"
CLUSTER_USER="e11704784"
SEED="${1:-1}"

echo "=========================================="
echo "Deploying Course Project to DataLAB"
echo "=========================================="
echo "Cluster: ${CLUSTER_HOST}"
echo "User:    ${CLUSTER_USER}"
echo "Seed:    ${SEED}"
echo ""

# Check if we're in the right directory
if [ ! -f "pyproject.toml" ]; then
    echo "❌ Error: Must run from mtrl repository root!"
    echo "   Current directory: $(pwd)"
    exit 1
fi

echo "📦 Step 1: Syncing code to cluster..."
rsync -avz --progress \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='.git' \
    --exclude='experiment_results' \
    --exclude='models' \
    --exclude='logs' \
    --exclude='wandb' \
    --exclude='*.sif' \
    --exclude='notes' \
    --exclude='results_local_test' \
    --exclude='logs_local_test' \
    ./ ${CLUSTER_USER}@${CLUSTER_HOST}:~/metaworld_project/source/

if [ $? -ne 0 ]; then
    echo "❌ Failed to sync code"
    exit 1
fi

echo ""
echo "✅ Code synced successfully!"
echo ""

echo "📤 Step 2: Submitting experiments..."
echo ""

# Submit jobs via SSH
ssh ${CLUSTER_USER}@${CLUSTER_HOST} << ENDSSH
set -e

# Create directories if they don't exist
mkdir -p ~/metaworld_project/{logs,models,wandb_cache}

# Navigate to scripts directory (angepasster Pfad)
cd ~/metaworld_project/source/docker/cluster/course_project

# Make scripts executable
chmod +x *.sh

# Submit all experiments
echo "Submitting experiments with seed ${SEED}..."
./submit_all.sh ${SEED}

ENDSSH

if [ $? -ne 0 ]; then
    echo "❌ Failed to submit jobs"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Monitor jobs: ssh ${CLUSTER_USER}@${CLUSTER_HOST} 'squeue -u \$USER'"
echo "  2. View logs:    ssh ${CLUSTER_USER}@${CLUSTER_HOST} 'tail -f ~/metaworld_project/logs/*.log'"
echo "  3. Check WandB:  https://wandb.ai"
echo ""
echo "To check job status:"
echo "  ssh ${CLUSTER_HOST}"
echo "  squeue -u ${CLUSTER_USER}"
echo ""
