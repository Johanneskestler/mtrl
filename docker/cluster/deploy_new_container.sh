#!/bin/bash
# Deploy new MTRL container with Python 3.12 to cluster

set -e

CLUSTER_HOST="datalab"
CLUSTER_USER="e11704784"
LOCAL_CONTAINER="mtrl_new.sif"
REMOTE_CONTAINER_DIR="/share/${CLUSTER_USER}/containers"

echo "=========================================="
echo "Deploy New MTRL Container to Cluster"
echo "=========================================="
echo ""

# Check if container exists
if [ ! -f "$LOCAL_CONTAINER" ]; then
    echo "❌ Container $LOCAL_CONTAINER not found!"
    echo "   Run conversion first"
    exit 1
fi

# Get container size
CONTAINER_SIZE=$(ls -lh "$LOCAL_CONTAINER" | awk '{print $5}')
echo "Container: $LOCAL_CONTAINER ($CONTAINER_SIZE)"
echo "Target:    ${CLUSTER_HOST}:${REMOTE_CONTAINER_DIR}/mtrl.sif"
echo ""

# Verify connectivity
echo "Verifying connection..."
if ! ssh "${CLUSTER_USER}@${CLUSTER_HOST}" "echo 'Connected'" > /dev/null 2>&1; then
    echo "❌ Cannot connect to ${CLUSTER_HOST}"
    exit 1
fi
echo "✓ Connected"
echo ""

# Backup old container if exists
echo "Backing up old container..."
ssh "${CLUSTER_USER}@${CLUSTER_HOST}" "
    if [ -f ${REMOTE_CONTAINER_DIR}/mtrl.sif ]; then
        mv ${REMOTE_CONTAINER_DIR}/mtrl.sif ${REMOTE_CONTAINER_DIR}/mtrl_backup_$(date +%Y%m%d_%H%M%S).sif
        echo '✓ Old container backed up'
    else
        echo '  No existing container to backup'
    fi
"

# Upload new container
echo ""
echo "Uploading new container (this will take several minutes)..."
scp -C "$LOCAL_CONTAINER" "${CLUSTER_USER}@${CLUSTER_HOST}:${REMOTE_CONTAINER_DIR}/mtrl.sif"

echo ""
echo "=========================================="
echo "✓ Deployment complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Update source code: ./upload_code_to_cluster.sh"
echo "  2. Test smoke run:     sbatch docker/cluster/mt10_smoke_2M.sh"
echo ""
