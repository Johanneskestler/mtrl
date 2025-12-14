#!/bin/bash
# Setup W&B on cluster (authenticate and test)

set -e

echo "=========================================="
echo "W&B Setup on Cluster"
echo "=========================================="
echo ""

# Get API key
read -p "Enter your W&B API key (from https://wandb.ai/authorize): " WANDB_API_KEY

if [ -z "$WANDB_API_KEY" ]; then
    echo "❌ API key required!"
    exit 1
fi

# Create .netrc for wandb auth (in container accessible location)
mkdir -p ~/.wandb
cat > ~/.wandb/netrc << EOF
machine api.wandb.ai
  login user
  password $WANDB_API_KEY
EOF

chmod 600 ~/.wandb/netrc

echo "✓ W&B credentials saved"
echo ""

# Create directories
mkdir -p ~/mtrl_project/{logs,models,wandb_cache}

echo "✓ Directories created"
echo ""
echo "=========================================="
echo "W&B Setup Complete!"
echo "=========================================="
echo ""
echo "To verify:"
echo "  wandb login  # Should show 'already logged in'"
echo ""
echo "To use in training:"
echo "  WANDB_MODE=online sbatch train_mt10_test.sh"
