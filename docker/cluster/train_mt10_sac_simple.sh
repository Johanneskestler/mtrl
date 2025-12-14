#!/bin/bash
# SBATCH script: Train MTRL SAC (simplest architecture) on MT10
# Target: TU Wien DataLAB A40 GPU
# Output structure matches: /home/e11704784/metaworld_project/

#SBATCH --job-name=mt10_sac_simple
#SBATCH --partition=a40
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --output=/home/%u/metaworld_project/logs/mt10_sac_simple_%j.log
#SBATCH --error=/home/%u/metaworld_project/logs/mt10_sac_simple_%j.err

set -e

# ============================================================================
# Configuration
# ============================================================================
PROJECT_DIR="/home/${SLURM_JOB_USER}/metaworld_project"
SOURCE_DIR="${PROJECT_DIR}/source/mtrl"
CONTAINER="${PROJECT_DIR}/mtrl.sif"
LOG_DIR="${PROJECT_DIR}/logs"
MODEL_DIR="${PROJECT_DIR}/models/mt10_sac_simple_${SLURM_JOB_ID}"
WANDB_CACHE="${PROJECT_DIR}/wandb_cache"

# Training config
TOTAL_STEPS=2000000
EVAL_FREQ=50000
SAVE_FREQ=100000
NUM_TASKS=10
SEED=42

# W&B config
WANDB_PROJECT="mtrl-cluster"
WANDB_ENTITY="${SLURM_JOB_USER}"
WANDB_RUN_NAME="MT10_SAC_Simple_GPU_${SLURM_JOB_ID}"

# ============================================================================
# Setup
# ============================================================================
echo "=========================================="
echo "MTRL SAC Training - Simple Architecture"
echo "=========================================="
echo "Job ID:       $SLURM_JOB_ID"
echo "User:         $SLURM_JOB_USER"
echo "GPU:          $(nvidia-smi --query-gpu=name --format=csv,noheader)"
echo "Time:         $(date)"
echo "Project Dir:  $PROJECT_DIR"
echo "Container:    $CONTAINER"
echo "=========================================="
echo ""

# Create output directories
mkdir -p "$LOG_DIR" "$MODEL_DIR" "$WANDB_CACHE"

# Verify container exists
if [ ! -f "$CONTAINER" ]; then
    echo "❌ Error: Container not found at $CONTAINER"
    echo "   Run: bash docker/cluster/build_docker.sh && bash docker/cluster/convert_to_singularity.sh"
    exit 1
fi

# Verify source code exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ Error: Source code not found at $SOURCE_DIR"
    echo "   Run: bash docker/cluster/upload_code_to_cluster.sh $SLURM_JOB_USER"
    exit 1
fi

# ============================================================================
# W&B Setup
# ============================================================================
echo "Setting up W&B..."

# Check if offline mode needed
if [ ! -f "${WANDB_CACHE}/.wandb_initialized" ]; then
    echo "W&B not initialized. Running setup..."
    
    # Try online mode first
    if [ -n "$WANDB_API_KEY" ]; then
        echo "Using WANDB_API_KEY from environment"
    else
        echo "No WANDB_API_KEY - will use offline mode"
    fi
    
    touch "${WANDB_CACHE}/.wandb_initialized"
fi

export WANDB_CACHE_DIR="$WANDB_CACHE"
export WANDB_CONFIG_DIR="$WANDB_CACHE"

# ============================================================================
# Python training script (executed in container)
# ============================================================================
read -r -d '' TRAIN_SCRIPT << 'PYTHON_EOF' || true
import os
import sys
import torch
import numpy as np
import wandb
from pathlib import Path

# Add source to path
sys.path.insert(0, os.environ['SOURCE_DIR'])

from mtrl.experiment import MTRLExperiment
from mtrl.config import ExperimentConfig
from mtrl.monitoring.wandb_logger import MtrlWandBLogger, WandBConfig

def main():
    # ========================================================================
    # Configuration
    # ========================================================================
    
    # Parse environment variables
    source_dir = Path(os.environ['SOURCE_DIR'])
    model_dir = Path(os.environ['MODEL_DIR'])
    log_dir = Path(os.environ['LOG_DIR'])
    
    total_steps = int(os.environ.get('TOTAL_STEPS', '2000000'))
    eval_freq = int(os.environ.get('EVAL_FREQ', '50000'))
    save_freq = int(os.environ.get('SAVE_FREQ', '100000'))
    num_tasks = int(os.environ.get('NUM_TASKS', '10'))
    seed = int(os.environ.get('SEED', '42'))
    job_id = os.environ.get('SLURM_JOB_ID', 'local')
    
    # W&B configuration
    wandb_config = WandBConfig(
        project=os.environ['WANDB_PROJECT'],
        entity=os.environ['WANDB_ENTITY'],
        run_name=os.environ['WANDB_RUN_NAME'],
        tags=['MTRL', 'SAC', 'MT10', 'Simple', f'GPU_{job_id}'],
        notes=f"Simple SAC architecture (no multi-head). Training on MT10 with {total_steps} steps.",
        offline=False,  # Try online, falls back to offline if no connection
        save_code=True
    )
    
    # Experiment configuration (simplest SAC architecture)
    exp_config = ExperimentConfig(
        # Environment
        env_name='mt10',
        num_tasks=num_tasks,
        
        # Algorithm: SAC (no multi-task extensions)
        algorithm='SAC',
        
        # Network: Simplest architecture (no multi-head, no task-specific modules)
        network_architecture='simple',  # Just standard FC layers
        hidden_sizes=[256, 256],
        
        # Training
        total_steps=total_steps,
        batch_size=256,
        learning_rate=3e-4,
        gamma=0.99,
        tau=0.005,
        target_entropy=-10,
        
        # Logging
        eval_frequency=eval_freq,
        save_frequency=save_freq,
        log_directory=str(log_dir),
        model_directory=str(model_dir),
        
        # System
        seed=seed,
        device='cuda' if torch.cuda.is_available() else 'cpu',
        num_workers=4,
    )
    
    # ========================================================================
    # Initialize W&B Logger
    # ========================================================================
    print("Initializing W&B...")
    wandb_logger = MtrlWandBLogger(wandb_config)
    
    # Log config
    wandb_logger.log_dict({
        'config/algorithm': 'SAC',
        'config/architecture': 'Simple (no multi-head)',
        'config/num_tasks': num_tasks,
        'config/total_steps': total_steps,
        'config/batch_size': exp_config.batch_size,
        'config/learning_rate': exp_config.learning_rate,
        'config/hidden_sizes': exp_config.hidden_sizes,
    })
    
    # ========================================================================
    # Create and Run Experiment
    # ========================================================================
    print(f"\n{'='*60}")
    print(f"Training MTRL SAC - Simple Architecture")
    print(f"{'='*60}")
    print(f"Environment:  MT10 ({num_tasks} tasks)")
    print(f"Algorithm:    SAC (standard, no multi-task extensions)")
    print(f"Architecture: Simple FC layers (no multi-head, no soft modules)")
    print(f"Total Steps:  {total_steps:,}")
    print(f"Batch Size:   {exp_config.batch_size}")
    print(f"Device:       {exp_config.device}")
    print(f"W&B Run:      {wandb_config.run_name}")
    print(f"{'='*60}\n")
    
    try:
        # Create experiment
        experiment = MTRLExperiment(config=exp_config)
        
        # Register W&B logger callback
        experiment.register_logger(wandb_logger)
        
        # Run training loop
        for step in range(0, total_steps, exp_config.eval_frequency):
            # Train
            metrics = experiment.train(
                num_steps=min(exp_config.eval_frequency, total_steps - step)
            )
            
            # Log to W&B
            wandb_logger.log_training_metrics(metrics)
            
            # Save checkpoint
            if step % exp_config.save_frequency == 0 and step > 0:
                checkpoint_path = model_dir / f"checkpoint_{step}.pt"
                experiment.save_checkpoint(checkpoint_path)
                wandb_logger.log_checkpoint(checkpoint_path)
                print(f"Saved checkpoint: {checkpoint_path}")
            
            # Evaluate
            if step % exp_config.eval_frequency == 0:
                eval_metrics = experiment.evaluate()
                wandb_logger.log_task_performance(eval_metrics)
                print(f"Step {step}/{total_steps} - Eval metrics: {eval_metrics}")
        
        # Final checkpoint
        final_model_path = model_dir / "final_model.pt"
        experiment.save_checkpoint(final_model_path)
        wandb_logger.log_checkpoint(final_model_path)
        
        print(f"\n✅ Training complete! Final model: {final_model_path}")
        wandb.finish()
        
    except Exception as e:
        print(f"\n❌ Training failed: {e}")
        wandb_logger.log_dict({'status': 'failed', 'error': str(e)})
        wandb.finish()
        raise

if __name__ == '__main__':
    main()
PYTHON_EOF

# ============================================================================
# Run Training in Container
# ============================================================================
echo ""
echo "Starting training in container..."
echo ""

# Export variables to container
export SOURCE_DIR="$SOURCE_DIR"
export MODEL_DIR="$MODEL_DIR"
export LOG_DIR="$LOG_DIR"
export TOTAL_STEPS="$TOTAL_STEPS"
export EVAL_FREQ="$EVAL_FREQ"
export SAVE_FREQ="$SAVE_FREQ"
export NUM_TASKS="$NUM_TASKS"
export SEED="$SEED"
export WANDB_PROJECT="$WANDB_PROJECT"
export WANDB_ENTITY="$WANDB_ENTITY"
export WANDB_RUN_NAME="$WANDB_RUN_NAME"

# Run Singularity container
singularity exec \
    --nv \
    --bind "$PROJECT_DIR:/workspace" \
    --bind "$WANDB_CACHE:/root/.cache/wandb" \
    --env "SOURCE_DIR=$SOURCE_DIR" \
    --env "MODEL_DIR=$MODEL_DIR" \
    --env "LOG_DIR=$LOG_DIR" \
    --env "TOTAL_STEPS=$TOTAL_STEPS" \
    --env "EVAL_FREQ=$EVAL_FREQ" \
    --env "SAVE_FREQ=$SAVE_FREQ" \
    --env "NUM_TASKS=$NUM_TASKS" \
    --env "SEED=$SEED" \
    --env "WANDB_PROJECT=$WANDB_PROJECT" \
    --env "WANDB_ENTITY=$WANDB_ENTITY" \
    --env "WANDB_RUN_NAME=$WANDB_RUN_NAME" \
    --env "WANDB_CACHE_DIR=/root/.cache/wandb" \
    "$CONTAINER" python << 'PYTHON_EOF'
$TRAIN_SCRIPT
PYTHON_EOF

TRAIN_STATUS=$?

# ============================================================================
# Cleanup & Report
# ============================================================================
echo ""
echo "=========================================="
echo "Training Completed"
echo "=========================================="
echo "Job ID:       $SLURM_JOB_ID"
echo "Time:         $(date)"
echo "Status:       $([ $TRAIN_STATUS -eq 0 ] && echo '✅ Success' || echo '❌ Failed')"
echo "Model Dir:    $MODEL_DIR"
echo "Logs:         $LOG_DIR/mt10_sac_simple_${SLURM_JOB_ID}.log"
echo "=========================================="
echo ""

if [ $TRAIN_STATUS -eq 0 ]; then
    echo "📊 To view results on W&B:"
    echo "   https://wandb.ai/$WANDB_ENTITY/$WANDB_PROJECT"
    echo ""
    echo "📥 To download models:"
    echo "   bash docker/cluster/download_models_from_cluster.sh e11704784 mt10_sac_simple_${SLURM_JOB_ID}"
fi

exit $TRAIN_STATUS
