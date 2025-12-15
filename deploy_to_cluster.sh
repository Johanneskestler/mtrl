#!/bin/bash
# Complete MTRL Cluster Deployment Pipeline
# 1. Build Docker locally
# 2. Convert to Singularity
# 3. Upload to DataLAB
# 4. Create training SBATCH script
# 5. Provide commands to submit job

set -e

echo "=========================================="
echo "MTRL Cluster Deployment Pipeline"
echo "=========================================="
echo ""

# Configuration
CLUSTER_USER="${1:-e11704784}"
CLUSTER_HOST="datalab"
REMOTE_PROJECT_DIR="/home/${CLUSTER_USER}/metaworld_project"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# ============================================================================
# Step 1: Build Docker Image
# ============================================================================
echo "[1/5] Building Docker image locally..."
echo ""

DOCKERFILE_PATH="$PROJECT_ROOT/docker/Dockerfile"

if [ ! -f "$DOCKERFILE_PATH" ]; then
    echo "❌ Error: Dockerfile not found at $DOCKERFILE_PATH"
    exit 1
fi

docker build \
    -t mtrl:latest \
    -f "$DOCKERFILE_PATH" \
    "$PROJECT_ROOT"

if [ $? -ne 0 ]; then
    echo "❌ Docker build failed"
    exit 1
fi

echo "✅ Docker build successful"
echo ""

# ============================================================================
# Step 2: Convert to Singularity
# ============================================================================
echo "[2/5] Converting Docker to Singularity..."
echo ""

# Check if singularity is available
if ! command -v singularity &> /dev/null; then
    echo "⚠️  Singularity not found. Install with: module load singularity"
    echo "   Or use: conda install -c conda-forge singularity"
    echo ""
    read -p "Continue without local Singularity conversion? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    echo "Note: Will convert on cluster with apptainer"
else
    OUTPUT_SIF="$PROJECT_ROOT/mtrl.sif"
    
    echo "Converting to: $OUTPUT_SIF"
    singularity build "$OUTPUT_SIF" "docker-daemon://mtrl:latest"
    
    if [ $? -ne 0 ]; then
        echo "❌ Singularity conversion failed"
        exit 1
    fi
    
    echo "✅ Singularity conversion successful"
    ls -lh "$OUTPUT_SIF"
fi
echo ""

# ============================================================================
# Step 3: Upload to DataLAB
# ============================================================================
echo "[3/5] Uploading code and container to DataLAB..."
echo ""

# Verify connectivity
if ! ssh "${CLUSTER_USER}@${CLUSTER_HOST}" "echo 'Connected'" > /dev/null 2>&1; then
    echo "❌ Cannot connect to ${CLUSTER_HOST}@${CLUSTER_USER}"
    echo "   Verify SSH config and VPN connection"
    exit 1
fi

# Create remote structure
echo "Creating remote directory structure..."
ssh "${CLUSTER_USER}@${CLUSTER_HOST}" << EOF
mkdir -p ${REMOTE_PROJECT_DIR}/{logs,models,wandb_cache,source/mtrl}
echo "✓ Directories created"
EOF

# Upload code
echo "Uploading source code..."
rsync -avP --delete \
    --exclude='.git' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='.pytest_cache' \
    --exclude='*.sif' \
    --exclude='build' \
    --exclude='dist' \
    "$PROJECT_ROOT/" \
    "${CLUSTER_USER}@${CLUSTER_HOST}:${REMOTE_PROJECT_DIR}/source/mtrl/"

if [ $? -ne 0 ]; then
    echo "❌ Upload failed"
    exit 1
fi

echo "✅ Code uploaded successfully"
echo ""

# Upload Singularity container if exists
if [ -f "$PROJECT_ROOT/mtrl.sif" ]; then
    echo "Uploading Singularity container (this may take a while)..."
    
    # Upload to /share/<user>/containers/ (persistent storage)
    SHARE_CONTAINER_DIR="/share/${CLUSTER_USER}/containers"
    
    echo "Ensuring container directory exists: ${SHARE_CONTAINER_DIR}"
    ssh "${CLUSTER_USER}@${CLUSTER_HOST}" "mkdir -p ${SHARE_CONTAINER_DIR}"
    
    scp "$PROJECT_ROOT/mtrl.sif" \
        "${CLUSTER_USER}@${CLUSTER_HOST}:${SHARE_CONTAINER_DIR}/mtrl.sif"
    
    if [ $? -ne 0 ]; then
        echo "⚠️  Container upload failed - will convert on cluster"
    else
        echo "✅ Container uploaded to ${SHARE_CONTAINER_DIR}/mtrl.sif"
    fi
else
    echo "⚠️  mtrl.sif not found - will convert on cluster with apptainer"
fi
echo ""

# ============================================================================
# Step 4: Setup W&B on cluster
# ============================================================================
echo "[4/5] W&B Setup Instructions..."
echo ""
echo "To enable W&B logging, run on cluster:"
echo ""
echo "  ssh ${CLUSTER_USER}@${CLUSTER_HOST}"
echo "  cd ${REMOTE_PROJECT_DIR}"
echo "  # Set your W&B API key (get from https://wandb.ai/authorize)"
echo "  export WANDB_API_KEY='your-api-key-here'"
echo "  # Verify:"
echo "  singularity exec --nv mtrl.sif wandb login"
echo ""
echo "Or run jobs with: sbatch --export=WANDB_API_KEY train_mt10_sac_simple.sh"
echo ""

# ============================================================================
# Step 5: Generate SBATCH script
# ============================================================================
echo "[5/5] Creating SBATCH training script..."
echo ""

SBATCH_SCRIPT="${REMOTE_PROJECT_DIR}/train_mt10_sac_simple.sh"

echo "SBATCH script location:"
echo "  ${CLUSTER_USER}@${CLUSTER_HOST}:${SBATCH_SCRIPT}"
echo ""
echo "The script has been copied to: ${PROJECT_ROOT}/docker/cluster/train_mt10_sac_simple.sh"
echo ""

# ============================================================================
# Final Summary
# ============================================================================
echo ""
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. SSH to cluster:"
echo "   ssh ${CLUSTER_USER}@${CLUSTER_HOST}"
echo ""
echo "2. Convert container (if not uploaded):"
echo "   cd ${REMOTE_PROJECT_DIR}"
echo "   apptainer build mtrl.sif docker://mtrl:latest"
echo ""
echo "3. Setup W&B authentication:"
echo "   export WANDB_API_KEY='your-key'"
echo ""
echo "4. Submit training job:"
echo "   cd ${REMOTE_PROJECT_DIR}/source/mtrl"
echo "   sbatch --export=WANDB_API_KEY=\$WANDB_API_KEY docker/cluster/train_mt10_a100_20m.sh"
echo ""
echo "5. Monitor job:"
echo "   squeue -u ${CLUSTER_USER}"
echo "   tail -f ${REMOTE_PROJECT_DIR}/logs/mt10_sac_20m_*.log"
echo ""
echo "6. View results:"
echo "   https://wandb.ai/${CLUSTER_USER}/mtrl-cluster"
echo ""
echo "=========================================="
echo ""
