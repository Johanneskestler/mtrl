#!/bin/bash
# Build MTRL Docker image for cluster deployment

set -e

echo "=========================================="
echo "Building MTRL Docker Image"
echo "=========================================="
echo ""

# Configuration
IMAGE_NAME="mtrl"
IMAGE_TAG="latest"
FULL_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

# Get script directory (docker/cluster -> docker -> mtrl root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

echo "Project root: $PROJECT_ROOT"
echo "Building image: $FULL_IMAGE"
echo ""

# Check if Dockerfile exists (in docker/ directory)
DOCKERFILE_PATH="$PROJECT_ROOT/docker/Dockerfile"

if [ ! -f "$DOCKERFILE_PATH" ]; then
    echo "❌ Error: Dockerfile not found at $DOCKERFILE_PATH"
    exit 1
fi

# Build Docker image
echo "Building Docker image... (this may take 10-15 minutes)"
docker build \
    -t "$FULL_IMAGE" \
    -f "$DOCKERFILE_PATH" \
    "$PROJECT_ROOT"

BUILD_STATUS=$?

if [ $BUILD_STATUS -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    echo "Image details:"
    docker images | grep "$IMAGE_NAME"
    echo ""
    echo "To test locally:"
    echo "  docker run --gpus all -it $FULL_IMAGE bash"
    echo ""
    echo "To convert to Singularity:"
    echo "  bash docker/cluster/build_docker.sh  # or run convert_to_singularity.sh"
else
    echo "❌ Build failed!"
    exit 1
fi
