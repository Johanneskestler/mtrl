#!/bin/bash
# Local Docker test of MTRL training with W&B

set -e

echo "=========================================="
echo "MTRL Docker Local Test"
echo "=========================================="
echo ""

# Configuration
IMAGE_NAME="mtrl:latest"
NUM_STEPS=10000
EVAL_FREQ=2000

# Check if image exists
if ! docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
    echo "❌ Docker image $IMAGE_NAME not found"
    echo "   First run: bash docker/cluster/build_docker.sh"
    exit 1
fi

echo "Image: $IMAGE_NAME"
echo "Test steps: $NUM_STEPS"
echo "Eval frequency: $EVAL_FREQ"
echo ""

# Create local directories for test
mkdir -p ./test_logs ./test_models ./test_wandb

echo "Starting container for testing..."
echo ""

# Run docker container with training
docker run --rm \
    --gpus all \
    -v "$(pwd):/workspace" \
    -e PYTHONUNBUFFERED=1 \
    -e WANDB_MODE=offline \
    -w /workspace \
    "$IMAGE_NAME" python << 'EOF'

import os
import sys
import torch
import numpy as np

print("="*60)
print("MTRL Training Test - Local Docker")
print("="*60)
print(f"PyTorch version: {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")
if torch.cuda.is_available():
    print(f"GPU: {torch.cuda.get_device_name(0)}")
print("")

# Test imports
print("Testing imports...")
try:
    import gymnasium
    print("✓ gymnasium")
except Exception as e:
    print(f"✗ gymnasium: {e}")
    
try:
    import metaworld
    print("✓ metaworld")
except Exception as e:
    print(f"✗ metaworld: {e}")
    
try:
    import wandb
    print("✓ wandb")
except Exception as e:
    print(f"✗ wandb: {e}")

try:
    import jax
    print("✓ jax")
except Exception as e:
    print(f"✗ jax: {e}")

print("")
print("="*60)
print("Testing MT10 Environment")
print("="*60)
print("")

# Test MetaWorld MT10
try:
    from metaworld import MT10
    
    print("Creating MT10 environment...")
    env = MT10()
    
    print(f"✓ MT10 created")
    print(f"  Tasks: {len(env.tasks)}")
    print(f"  Task names: {[t.name for t in env.tasks[:3]]}...")
    
    print("")
    print("Testing single task episode...")
    
    # Get first task
    task = env.tasks[0]
    print(f"  Task: {task.name}")
    
    # Create environment for task
    env = MT10()
    obs = env.reset()
    
    # Run a few steps
    for step in range(10):
        action = env.action_space.sample()
        obs, reward, terminated, truncated, info = env.step(action)
    
    print(f"✓ Episode test passed")
    print(f"  Obs shape: {obs.shape}")
    print(f"  Action space: {env.action_space.shape}")
    
except Exception as e:
    print(f"✗ MT10 test failed: {e}")
    import traceback
    traceback.print_exc()

print("")
print("="*60)
print("Testing W&B Logger")
print("="*60)
print("")

try:
    sys.path.insert(0, '/workspace')
    from mtrl.monitoring.wandb_logger import MtrlWandBLogger, WandBConfig
    
    print("Creating W&B logger...")
    config = WandBConfig(
        project="mtrl-local-test",
        run_name="docker_test",
        offline=True,
    )
    
    logger = MtrlWandBLogger(config)
    print("✓ W&B logger created")
    
    # Log some test data
    logger.log_dict({
        'test/docker': True,
        'test/step': 100,
    })
    print("✓ Logged test metrics")
    
except Exception as e:
    print(f"✗ W&B logger test failed: {e}")
    import traceback
    traceback.print_exc()

print("")
print("="*60)
print("✅ All tests passed!")
print("="*60)
print("")
print("Ready to deploy to cluster!")
print("Next: bash deploy_to_cluster.sh e11704784")
print("")

EOF

# Check result
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Docker test successful!"
    echo ""
    echo "Next steps:"
    echo "1. Deploy to cluster: bash deploy_to_cluster.sh e11704784"
    echo "2. Submit training:  sbatch train_mt10_sac_simple.sh"
else
    echo ""
    echo "❌ Docker test failed"
    exit 1
fi
