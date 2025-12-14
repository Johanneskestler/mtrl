#!/bin/bash
# Convert Docker image to Singularity (.sif) for cluster deployment

set -e

echo "=========================================="
echo "Convert MTRL Docker → Singularity"
echo "=========================================="
echo ""

# Configuration
DOCKER_IMAGE="mtrl:latest"
SIF_OUTPUT="mtrl.sif"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if Docker image exists
echo "Checking Docker image: $DOCKER_IMAGE"
if ! docker images | grep -q "^mtrl"; then
    echo "❌ Docker image 'mtrl:latest' not found!"
    echo "   Please run: bash docker/cluster/build_docker.sh"
    exit 1
fi

echo "✓ Docker image found"
echo ""

# Build Singularity image from Docker daemon
echo "Converting to Singularity (this may take 10-20 minutes)..."
echo "Output: $SIF_OUTPUT (~10-15 GB)"
echo ""

apptainer build \
    --force \
    "$SIF_OUTPUT" \
    "docker-daemon://$DOCKER_IMAGE"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Conversion successful!"
    echo ""
    echo "Output file:"
    ls -lh "$SIF_OUTPUT"
    echo ""
    echo "To test Singularity image:"
    echo "  apptainer exec --nv $SIF_OUTPUT python --version"
    echo ""
    echo "To upload to cluster:"
    echo "  scp $SIF_OUTPUT username@cluster.datalab.tuwien.ac.at:~/"
else
    echo "❌ Conversion failed!"
    exit 1
fi
