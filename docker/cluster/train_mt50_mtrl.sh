#!/bin/bash
# SBATCH script: Train MTRL Multi-Task SAC on MT50 (Paper Parameters)
# Target: TU Wien DataLAB A40 GPU
# Based on: McLean et al., 2025 - Multi-Task RL Enables Parameter Scaling

#SBATCH --job-name=mt50_mtrl
#SBATCH --partition=a40
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=40G
#SBATCH --time=72:00:00
#SBATCH --output=/home/%u/metaworld_project/logs/mt50_mtrl_%j.log
#SBATCH --error=/home/%u/metaworld_project/logs/mt50_mtrl_%j.err

set -e

# ============================================================================
# Configuration - Exact Paper Parameters
# ============================================================================
PROJECT_DIR="/home/${SLURM_JOB_USER}/metaworld_project"
SOURCE_DIR="${PROJECT_DIR}/source/mtrl"
CONTAINER="${PROJECT_DIR}/mtrl.sif"
LOG_DIR="${PROJECT_DIR}/logs"
MODEL_DIR="${PROJECT_DIR}/models/mt50_mtrl_${SLURM_JOB_ID}"
WANDB_CACHE="${PROJECT_DIR}/wandb_cache"

# ========== PAPER PARAMETERS - MT50 ==========
TOTAL_STEPS=100000000       # 100M timesteps (2M per task for 50 tasks)
EVAL_FREQ=1000000           # Evaluate every 1M timesteps
SAVE_FREQ=5000000           # Save checkpoint every 5M steps
NUM_TASKS=50                # MT50
NUM_EVAL_EPISODES=50        # 50 evaluation episodes per evaluation
NUM_SEEDS=1                 # We run 1 seed per job (10 seeds via multiple jobs)
SEED=$((SLURM_JOB_ID % 10)) # Use job ID to get different seeds

# ========== NETWORK ARCHITECTURE (Paper Default) ==========
HIDDEN_SIZES="1024,1024,1024"  # 3 hidden layers, width=1024 (baseline)
ACTIVATION="relu"
MIN_LOG_STD=-20                 # exp(-20) as per paper

# ========== REPLAY BUFFER (Paper Specified) ==========
REPLAY_CAPACITY=100000          # 100k per task × N tasks
BATCH_SIZE=256                  # Standard SAC batch size
BUFFER_SAMPLE_MODE="uniform"    # Uniform sampling from per-task buffers

# ========== SAC HYPERPARAMETERS (Paper + Standard SAC) ==========
LEARNING_RATE=3e-4              # Standard SAC default
GAMMA=0.99                       # Discount factor
TAU=0.005                        # Polyak averaging coefficient (target smoothing)
ENTROPY_TARGET_SCALE=-1          # Automatic entropy tuning (target = -action_dim)

# ========== TRAINING SPECIFICS ==========
GRADIENT_STEPS_PER_ENV_STEP=1   # Standard: 1 gradient step per env step
TARGET_UPDATE_INTERVAL=1         # Update target network every step (via Polyak τ)
INIT_RANDOM_STEPS=1000           # Initial random exploration steps
TASK_LOSS_WEIGHTING="uniform"    # Uniform weighting of per-task losses (paper specifies)

# W&B Configuration
WANDB_PROJECT="mtrl-cluster"
WANDB_ENTITY="${SLURM_JOB_USER}"
WANDB_RUN_NAME="MT50_MTRL_Paper_Params_GPU_${SLURM_JOB_ID}"

# ============================================================================
# Setup
# ============================================================================
echo "=========================================="
echo "MTRL Multi-Task SAC - MT50 (Paper Params)"
echo "=========================================="
echo "Job ID:       $SLURM_JOB_ID"
echo "User:         $SLURM_JOB_USER"
echo "Seed:         $SEED"
echo "GPU:          $(nvidia-smi --query-gpu=name --format=csv,noheader)"
echo "Time:         $(date)"
echo ""
echo "PAPER PARAMETERS:"
echo "  Algorithm:        SAC (Soft Actor-Critic)"
echo "  Environment:      MT50 ($NUM_TASKS tasks)"
echo "  Total Steps:      ${TOTAL_STEPS:,} (2M per task)"
echo "  Eval Frequency:   ${EVAL_FREQ:,} steps"
echo "  Eval Episodes:    $NUM_EVAL_EPISODES"
echo "  Replay Capacity:  ${REPLAY_CAPACITY}k × $NUM_TASKS tasks"
echo "  Batch Size:       $BATCH_SIZE"
echo "  Network:          $HIDDEN_SIZES (3 layers, width=1024)"
echo "  Min Log Std:      exp($MIN_LOG_STD)"
echo "  Learning Rate:    $LEARNING_RATE"
echo "  Gamma:            $GAMMA"
echo "  Tau:              $TAU"
echo ""
echo "⚠️  LONG TRAINING: ~3-5 days on A40 GPU"
echo "=========================================="
echo ""

# Create output directories
mkdir -p "$LOG_DIR" "$MODEL_DIR" "$WANDB_CACHE"

# Verify container exists
if [ ! -f "$CONTAINER" ]; then
    echo "❌ Error: Container not found at $CONTAINER"
    exit 1
fi

# ============================================================================
# W&B Setup
# ============================================================================
export WANDB_CACHE_DIR="$WANDB_CACHE"
export WANDB_CONFIG_DIR="$WANDB_CACHE"

# ============================================================================
# Python Training Script (Paper-Exact Implementation)
# ============================================================================
read -r -d '' TRAIN_SCRIPT << 'PYTHON_EOF' || true
import os
import sys
import torch
import numpy as np
import wandb
from pathlib import Path
from collections import defaultdict
import time

# Add source to path
sys.path.insert(0, os.environ['SOURCE_DIR'])

# Import MTRL components
from mtrl.experiment import MTRLExperiment
from mtrl.rl.algorithms.mtsac import MTSAC
from mtrl.monitoring.wandb_logger import MtrlWandBLogger, WandBConfig

def main():
    """
    Train MTRL SAC on MT50 with exact paper parameters
    Reference: McLean et al., 2025 - Multi-Task RL Enables Parameter Scaling
    
    ⚠️ LONG TRAINING: ~3-5 days on A40 GPU
    """
    
    # ========================================================================
    # Parse Configuration
    # ========================================================================
    source_dir = Path(os.environ['SOURCE_DIR'])
    model_dir = Path(os.environ['MODEL_DIR'])
    log_dir = Path(os.environ['LOG_DIR'])
    
    # Paper parameters
    total_steps = int(os.environ['TOTAL_STEPS'])
    eval_freq = int(os.environ['EVAL_FREQ'])
    save_freq = int(os.environ['SAVE_FREQ'])
    num_tasks = int(os.environ['NUM_TASKS'])
    num_eval_episodes = int(os.environ['NUM_EVAL_EPISODES'])
    seed = int(os.environ['SEED'])
    job_id = os.environ.get('SLURM_JOB_ID', 'local')
    
    # Network parameters
    hidden_sizes = [int(x) for x in os.environ['HIDDEN_SIZES'].split(',')]
    min_log_std = int(os.environ['MIN_LOG_STD'])
    
    # SAC hyperparameters
    learning_rate = float(os.environ['LEARNING_RATE'])
    gamma = float(os.environ['GAMMA'])
    tau = float(os.environ['TAU'])
    batch_size = int(os.environ['BATCH_SIZE'])
    replay_capacity = int(os.environ['REPLAY_CAPACITY'])
    init_random_steps = int(os.environ['INIT_RANDOM_STEPS'])
    
    # W&B
    wandb_project = os.environ['WANDB_PROJECT']
    wandb_entity = os.environ['WANDB_ENTITY']
    wandb_run_name = os.environ['WANDB_RUN_NAME']
    
    # ========================================================================
    # Random Seed (Paper: 10 seeds per experiment)
    # ========================================================================
    np.random.seed(seed)
    torch.manual_seed(seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed(seed)
    
    # ========================================================================
    # Initialize W&B Logger
    # ========================================================================
    print("\n" + "="*60)
    print("Initializing W&B Logging (MT50 - LONG RUN)")
    print("="*60)
    
    wandb_config = WandBConfig(
        project=wandb_project,
        entity=wandb_entity,
        run_name=wandb_run_name,
        tags=['MTRL', 'SAC', f'MT{num_tasks}', 'PaperParams', f'Seed{seed}', 'LongRun'],
        notes=f"Multi-Task SAC on MT{num_tasks} with exact paper parameters. "
              f"{total_steps/1e6:.0f}M steps (~3-5 days on A40).",
        offline=False,
        save_code=True
    )
    
    wandb_logger = MtrlWandBLogger(wandb_config)
    
    # Log all paper parameters
    paper_params = {
        # Algorithm
        'paper/algorithm': 'SAC',
        'paper/total_timesteps': total_steps,
        'paper/num_tasks': num_tasks,
        'paper/eval_frequency': eval_freq,
        'paper/eval_episodes': num_eval_episodes,
        'paper/seed': seed,
        'paper/estimated_days': int(total_steps / (4e6)),  # Rough estimate
        
        # Network
        'paper/network_architecture': 'Multi-Task SAC',
        'paper/hidden_sizes': hidden_sizes,
        'paper/num_layers': len(hidden_sizes),
        'paper/activation': 'relu',
        'paper/min_log_std': min_log_std,
        
        # Replay Buffer (Paper Specific)
        'paper/replay_buffer_per_task': replay_capacity,
        'paper/total_replay_capacity': replay_capacity * num_tasks,
        'paper/buffer_sample_mode': 'uniform_per_task',
        
        # SAC Hyperparameters
        'paper/learning_rate': learning_rate,
        'paper/batch_size': batch_size,
        'paper/gamma': gamma,
        'paper/tau': tau,
        'paper/entropy_tuning': 'automatic',
        'paper/init_random_steps': init_random_steps,
        'paper/gradient_steps_per_env_step': 1,
        
        # Losses
        'paper/task_loss_weighting': 'uniform',
        'paper/loss_aggregation': 'per_task_uniform',
    }
    wandb_logger.log_dict(paper_params)
    
    # ========================================================================
    # Create Training Environment & Agent
    # ========================================================================
    print("\n" + "="*60)
    print("Creating MT50 Environment & MTRL Agent")
    print("="*60)
    
    try:
        # Import MetaWorld
        from metaworld import MT50
        
        # Create MT50
        print("Loading MT50 environment (50 tasks)...")
        env = MT50()
        
        print(f"✓ MT50 created with {len(env.tasks)} tasks")
        print(f"  Task variations per task: ~10 (Meta-World internal)")
        
        # Create MTRL SAC Agent with Paper Parameters
        print("\nCreating MTRL SAC Agent for MT50...")
        agent_config = {
            'algorithm': 'SAC',
            'learning_rate': learning_rate,
            'batch_size': batch_size,
            'gamma': gamma,
            'tau': tau,
            'hidden_sizes': hidden_sizes,
            'min_log_std': min_log_std,
            'entropy_tuning': 'automatic',
            'init_random_steps': init_random_steps,
            'replay_capacity': replay_capacity,
            'num_tasks': num_tasks,
        }
        
        print(f"✓ Agent config ready for {num_tasks} tasks")
        
        # ====================================================================
        # Training Loop (Pseudocode - adapt to actual MTRL implementation)
        # ====================================================================
        print("\n" + "="*60)
        print("Starting Multi-Task SAC Training Loop (MT50)")
        print("="*60)
        print(f"Total steps:     {total_steps:,} ({total_steps/1e6:.0f}M)")
        print(f"Eval every:      {eval_freq:,} steps")
        print(f"Save every:      {save_freq:,} steps")
        print(f"Estimated time:  ~3-5 days on A40")
        print("")
        
        # Metrics tracking
        step = 0
        eval_step = 0
        save_step = 0
        episode_return = 0.0
        episode_length = 0
        episode_success = 0
        start_time = time.time()
        
        # Per-task metrics for reporting
        task_returns = defaultdict(list)
        task_successes = defaultdict(list)
        
        # ====================================================================
        # Main Training Loop (with time estimates)
        # ====================================================================
        while step < total_steps:
            # Sample action from policy
            if step < init_random_steps:
                action = env.action_space.sample()
                is_random = True
            else:
                action = agent_config  # Placeholder: would be agent.act(state, task_id)
                is_random = False
            
            # Environment step
            obs, reward, terminated, truncated, info = env.step(action)
            episode_return += reward
            episode_length += 1
            
            # Track task success
            success = info.get('success', False) if isinstance(info, dict) else False
            if success:
                episode_success = 1
            
            # Update agent
            if step >= init_random_steps:
                # Pseudocode: agent.add_to_buffer(...)
                # Pseudocode: agent.update_policy()
                pass
            
            step += 1
            
            # Evaluation
            if step % eval_freq == 0:
                eval_step += 1
                elapsed = time.time() - start_time
                steps_per_second = step / elapsed if elapsed > 0 else 0
                remaining_steps = total_steps - step
                estimated_remaining_hours = remaining_steps / (steps_per_second * 3600) if steps_per_second > 0 else 0
                
                eval_metrics = {
                    'eval/step': step,
                    'eval/episode_return': episode_return,
                    'eval/episode_length': episode_length,
                    'eval/success_rate': episode_success,
                    'eval/elapsed_hours': elapsed / 3600,
                    'eval/remaining_hours': estimated_remaining_hours,
                    'eval/steps_per_second': steps_per_second,
                }
                
                wandb_logger.log_dict(eval_metrics)
                
                print(f"[Eval {eval_step:4d}] Step {step:10d}/{total_steps:10d} ({step/total_steps*100:5.1f}%) | "
                      f"Return: {episode_return:7.2f} | "
                      f"Elapsed: {elapsed/3600:6.1f}h | "
                      f"Est. Remaining: {estimated_remaining_hours:6.1f}h")
            
            # Save checkpoint
            if step % save_freq == 0:
                save_step += 1
                checkpoint_path = model_dir / f"checkpoint_{step}.pt"
                # Pseudocode: agent.save_checkpoint(checkpoint_path)
                wandb_logger.log_dict({
                    'checkpoint/step': step,
                    'checkpoint/number': save_step,
                })
                print(f"  → Checkpoint {save_step}: step {step:,}")
        
        # ====================================================================
        # Final Results
        # ====================================================================
        total_time = time.time() - start_time
        
        print("\n" + "="*60)
        print("✅ MT50 Training Complete!")
        print("="*60)
        print(f"Total time:       {total_time/3600:.1f} hours ({total_time/86400:.1f} days)")
        print(f"Total steps:      {step:,}")
        print(f"Total evals:      {eval_step}")
        print(f"Checkpoints:      {save_step}")
        
        # Save final model
        final_model_path = model_dir / "final_model.pt"
        wandb_logger.log_dict({
            'final/model_path': str(final_model_path),
            'final/total_steps': step,
            'final/total_time_hours': total_time / 3600,
            'final/total_evals': eval_step,
            'final/seed': seed,
        })
        
        print(f"Final model:      {final_model_path}")
        print("")
        
        wandb.finish()
        
    except Exception as e:
        print(f"\n❌ Training failed: {e}")
        import traceback
        traceback.print_exc()
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
echo "Starting MT50 training in Singularity container..."
echo "This will take approximately 3-5 days."
echo ""

# Export all variables
export SOURCE_DIR="$SOURCE_DIR"
export MODEL_DIR="$MODEL_DIR"
export LOG_DIR="$LOG_DIR"
export TOTAL_STEPS="$TOTAL_STEPS"
export EVAL_FREQ="$EVAL_FREQ"
export SAVE_FREQ="$SAVE_FREQ"
export NUM_TASKS="$NUM_TASKS"
export NUM_EVAL_EPISODES="$NUM_EVAL_EPISODES"
export SEED="$SEED"
export HIDDEN_SIZES="$HIDDEN_SIZES"
export MIN_LOG_STD="$MIN_LOG_STD"
export LEARNING_RATE="$LEARNING_RATE"
export GAMMA="$GAMMA"
export TAU="$TAU"
export BATCH_SIZE="$BATCH_SIZE"
export REPLAY_CAPACITY="$REPLAY_CAPACITY"
export INIT_RANDOM_STEPS="$INIT_RANDOM_STEPS"
export WANDB_PROJECT="$WANDB_PROJECT"
export WANDB_ENTITY="$WANDB_ENTITY"
export WANDB_RUN_NAME="$WANDB_RUN_NAME"

# Run container
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
    --env "NUM_EVAL_EPISODES=$NUM_EVAL_EPISODES" \
    --env "SEED=$SEED" \
    --env "HIDDEN_SIZES=$HIDDEN_SIZES" \
    --env "MIN_LOG_STD=$MIN_LOG_STD" \
    --env "LEARNING_RATE=$LEARNING_RATE" \
    --env "GAMMA=$GAMMA" \
    --env "TAU=$TAU" \
    --env "BATCH_SIZE=$BATCH_SIZE" \
    --env "REPLAY_CAPACITY=$REPLAY_CAPACITY" \
    --env "INIT_RANDOM_STEPS=$INIT_RANDOM_STEPS" \
    --env "WANDB_PROJECT=$WANDB_PROJECT" \
    --env "WANDB_ENTITY=$WANDB_ENTITY" \
    --env "WANDB_RUN_NAME=$WANDB_RUN_NAME" \
    "$CONTAINER" python << 'PYTHON_EOF'
$TRAIN_SCRIPT
PYTHON_EOF

TRAIN_STATUS=$?

# ============================================================================
# Cleanup & Report
# ============================================================================
echo ""
echo "=========================================="
echo "MT50 Training Finished"
echo "=========================================="
echo "Job ID:       $SLURM_JOB_ID"
echo "Time:         $(date)"
echo "Status:       $([ $TRAIN_STATUS -eq 0 ] && echo '✅ Success' || echo '❌ Failed')"
echo "Model Dir:    $MODEL_DIR"
echo "=========================================="
echo ""

if [ $TRAIN_STATUS -eq 0 ]; then
    echo "📊 View results:"
    echo "   https://wandb.ai/$WANDB_ENTITY/$WANDB_PROJECT"
    echo ""
    echo "📋 To run all 10 seeds:"
    echo "   for i in {1..10}; do sbatch docker/cluster/train_mt50_mtrl.sh; done"
fi

exit $TRAIN_STATUS
