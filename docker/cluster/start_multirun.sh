#!/bin/bash
# Quick setup script for multi-seed baseline run
# Run this on the cluster to setup W&B and start the job

echo "=========================================="
echo "MT10 Multi-Seed Baseline Setup"
echo "=========================================="
echo ""

# Step 1: Setup W&B key
echo "[1/3] Setting up W&B API key..."
if [ ! -f "$HOME/.wandb_api_key" ]; then
    bash ~/metaworld_project/source/mtrl/docker/cluster/setup_wandb_key.sh
else
    echo "✅ W&B key already configured"
fi

echo ""
echo "[2/3] Verifying setup..."

# Check container
if [ ! -f "/share/e11704784/containers/mtrl.sif" ]; then
    echo "❌ Container not found at /share/e11704784/containers/mtrl.sif"
    echo "   Please upload it first!"
    exit 1
fi
echo "✅ Container found"

# Check source
if [ ! -d "$HOME/metaworld_project/source/mtrl" ]; then
    echo "❌ Source code not found"
    exit 1
fi
echo "✅ Source code found"

# Check directories
mkdir -p "$HOME/metaworld_project/logs"
mkdir -p "$HOME/metaworld_project/results"
mkdir -p "$HOME/metaworld_project/wandb_cache"
echo "✅ Directories ready"

echo ""
echo "[3/3] Submitting multi-seed job (5 parallel runs)..."
cd ~/metaworld_project/source/mtrl

sbatch docker/cluster/mt10_baseline_multirun.sh

echo ""
echo "=========================================="
echo "✅ Job submitted!"
echo "=========================================="
echo ""
echo "Monitor with:"
echo "  squeue -u \$USER"
echo "  tail -f ~/metaworld_project/logs/mt10_baseline_seed1_*.log"
echo ""
echo "View results:"
echo "  https://wandb.ai/e11704784/mtrl-paper-baseline"
echo ""
echo "=========================================="
