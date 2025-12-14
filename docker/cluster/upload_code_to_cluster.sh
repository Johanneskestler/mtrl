#!/bin/bash
# Upload MTRL code to TU Wien DataLAB cluster
# Matches structure: /home/e11704784/metaworld_project/

set -e

echo "=========================================="
echo "Upload MTRL to DataLAB Cluster"
echo "=========================================="
echo ""

# Configuration
CLUSTER_HOST="datalab"
CLUSTER_USER="${1:-e11704784}"
REMOTE_PROJECT_DIR="/home/${CLUSTER_USER}/metaworld_project"

# Validate input
if [ -z "$CLUSTER_USER" ]; then
    echo "Usage: ./upload_code_to_cluster.sh <username>"
    echo "Example: ./upload_code_to_cluster.sh e11704784"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

echo "Local:        $PROJECT_ROOT"
echo "Remote:       ${CLUSTER_HOST}:${REMOTE_PROJECT_DIR}/source/mtrl"
echo "User:         $CLUSTER_USER"
echo ""

# Verify connectivity
echo "Verifying connection to cluster..."
if ! ssh "${CLUSTER_USER}@${CLUSTER_HOST}" "echo 'Connected'" > /dev/null 2>&1; then
    echo "❌ Cannot connect to ${CLUSTER_HOST}"
    echo "   Check your SSH config and VPN connection"
    exit 1
fi
echo "✓ Connection OK"
echo ""

# Create remote directories (match DataLAB structure)
echo "Creating remote directories..."
ssh "${CLUSTER_USER}@${CLUSTER_HOST}" "mkdir -p ${REMOTE_PROJECT_DIR}/{logs,models,wandb_cache,source/mtrl}"

# Upload code to source/mtrl/
echo "Uploading code to ${REMOTE_PROJECT_DIR}/source/mtrl/ (this may take a few minutes)..."
rsync -avP \
    --exclude='.git' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='.pytest_cache' \
    --exclude='build' \
    --exclude='dist' \
    --exclude='*.egg-info' \
    --exclude='docker/cluster/.sif' \
    "$PROJECT_ROOT/" \
    "${CLUSTER_USER}@${CLUSTER_HOST}:${REMOTE_PROJECT_DIR}/source/mtrl/"
    --exclude='*.pyc' \
    --exclude='wandb' \
    --exclude='logs' \
    --exclude='models' \
    --exclude='.sif' \
    "${PROJECT_ROOT}/" \
    "${CLUSTER_USER}@${CLUSTER_HOST}:${REMOTE_PROJECT_DIR}/source/mtrl/"

echo ""
echo "✅ Upload complete!"
echo ""
echo "Next steps:"
echo "  1. SSH to cluster: ssh ${CLUSTER_USER}@${CLUSTER_HOST}"
echo "  2. Setup W&B: bash ${REMOTE_PROJECT_DIR}/source/mtrl/docker/cluster/setup_wandb.sh"
echo "  3. Test job: sbatch ${REMOTE_PROJECT_DIR}/source/mtrl/docker/cluster/train_mt10_test.sh"
