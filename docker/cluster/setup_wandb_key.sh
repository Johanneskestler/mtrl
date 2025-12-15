#!/bin/bash
# Setup W&B API Key for cluster jobs
# Run once: bash docker/cluster/setup_wandb_key.sh

echo "=========================================="
echo "W&B API Key Setup"
echo "=========================================="
echo ""

WANDB_KEY_FILE="/home/e11704784/.wandb_api_key"

if [ -f "$WANDB_KEY_FILE" ]; then
    echo "✅ W&B API key already configured at: $WANDB_KEY_FILE"
    echo ""
    read -p "Do you want to update it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing key."
        exit 0
    fi
fi

echo "Get your W&B API key from: https://wandb.ai/authorize"
echo ""
read -sp "Enter your W&B API key: " WANDB_API_KEY
echo ""

if [ -z "$WANDB_API_KEY" ]; then
    echo "❌ Error: No API key provided"
    exit 1
fi

# Save to file with restricted permissions
echo "$WANDB_API_KEY" > "$WANDB_KEY_FILE"
chmod 600 "$WANDB_KEY_FILE"

echo ""
echo "✅ W&B API key saved to: $WANDB_KEY_FILE"
echo ""
echo "Your SBATCH scripts will now automatically load this key."
echo "No need to use --export=WANDB_API_KEY anymore!"
echo ""
echo "To verify, run:"
echo "  cat $WANDB_KEY_FILE"
echo "=========================================="
