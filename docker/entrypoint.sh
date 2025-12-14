#!/bin/bash
# MTRL Docker Entrypoint
# Handles headless rendering setup and environment configuration

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}MTRL Docker Entrypoint${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Setup MuJoCo rendering
echo -e "${YELLOW}Setting up headless rendering...${NC}"
export MUJOCO_GL=${MUJOCO_GL:-egl}
echo "  MUJOCO_GL: $MUJOCO_GL"

# PyOpenGL configuration for headless mode
export PYOPENGL_PLATFORM=${PYOPENGL_PLATFORM:-egl}
echo "  PYOPENGL_PLATFORM: $PYOPENGL_PLATFORM"

# CUDA settings
export CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-0}
echo "  CUDA_VISIBLE_DEVICES: $CUDA_VISIBLE_DEVICES"

# Python settings
export PYTHONUNBUFFERED=1
export PYTHONDONTWRITEBYTECODE=1
echo "  PYTHONUNBUFFERED: 1"
echo ""

# Verify CUDA (if GPUs available)
echo -e "${YELLOW}Checking CUDA availability...${NC}"
python -c "
import torch
if torch.cuda.is_available():
    print(f'  ✅ CUDA available: {torch.cuda.get_device_name(0)}')
    print(f'  ✅ CUDA version: {torch.version.cuda}')
else:
    print('  ℹ️  Running on CPU')
" || true
echo ""

# Execute the command passed to docker
echo -e "${GREEN}Executing: $@${NC}"
echo ""
exec "$@"
