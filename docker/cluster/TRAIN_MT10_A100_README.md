# MT10 A100 Training Script

## Overview
SBATCH script for training Multi-Task SAC on MetaWorld MT10 with exact paper parameters from McLean et al. (2025).

**Script:** `train_mt10_a100_20m.sh`  
**Target GPU:** A100 (40GB)  
**Training Steps:** 20M timesteps  
**Paper:** Multi-Task RL Enables Parameter Scaling (arXiv:2503.05126)

---

## Key Features

✅ **Paper-Exact Parameters**
- Batch size: 1280
- Replay buffer: 1M steps
- Network: 3 layers × 1024 units (multi-head SAC)
- Gamma: 0.99, Twin Q-networks

✅ **Automatic Checkpointing**
- Saves checkpoints every ~1M steps (managed by Orbax)
- Keeps best 5 checkpoints by success rate
- Final model saved at end
- Full resume support via `--resume` flag

✅ **W&B Integration**
- Automatic logging of training metrics
- Success rates per task
- Checkpoint artifacts uploaded
- Run name: `MT10_SAC_20M_seed{seed}_job{jobid}`

✅ **Robust Setup**
- Container stored in `/share/{user}/containers/` (persistent)
- Results in `~/metaworld_project/results/`
- Logs in `~/metaworld_project/logs/`
- Auto-detects W&B credentials

---

## Usage

### 1. Prerequisites
Upload code and container to cluster:
```bash
# On your local machine
./deploy_to_cluster.sh e11704784
```

This uploads:
- Code → `~/metaworld_project/source/mtrl/`
- Container → `/share/e11704784/containers/mtrl.sif`

### 2. Submit Single Training Run
```bash
# On cluster
cd ~/metaworld_project/source/mtrl
export WANDB_API_KEY="your-wandb-api-key"

sbatch --export=WANDB_API_KEY=$WANDB_API_KEY docker/cluster/train_mt10_a100_20m.sh
```

### 3. Submit Multiple Seeds (Array Job)
To run 5 seeds in parallel:
```bash
sbatch --export=WANDB_API_KEY=$WANDB_API_KEY \
       --array=1-5 \
       docker/cluster/train_mt10_a100_20m.sh
```

Each seed will use `SLURM_ARRAY_TASK_ID` as its random seed.

### 4. Monitor Job
```bash
# Check queue
squeue -u $USER

# Watch logs (live)
tail -f ~/metaworld_project/logs/mt10_sac_20m_*.log

# Check GPU usage
ssh <compute-node>
nvidia-smi
```

### 5. Resume Interrupted Training
If a job is cancelled or crashes:
```bash
# Edit train_mt10_a100_20m.sh, line ~145:
# Add --resume flag to python command

python experiments/mt10_mtmhsac.py \
    --seed "$SEED" \
    --track \
    --wandb-project "$WANDB_PROJECT" \
    --wandb-entity "$WANDB_ENTITY" \
    --data-dir "/workspace/results/mt10_sac_${SLURM_JOB_ID}" \
    --resume  # <-- Add this

# Resubmit
sbatch --export=WANDB_API_KEY=$WANDB_API_KEY docker/cluster/train_mt10_a100_20m.sh
```

---

## Output Structure

```
~/metaworld_project/
├── logs/
│   ├── mt10_sac_20m_<jobid>.log       # Stdout
│   └── mt10_sac_20m_<jobid>.err       # Stderr
├── results/
│   └── mt10_sac_<jobid>/
│       └── checkpoints/
│           ├── 1/                      # Step 1M checkpoint
│           ├── 2/                      # Step 2M checkpoint
│           ├── ...
│           ├── 20/                     # Step 20M checkpoint
│           └── 21/                     # Final evaluation checkpoint
└── wandb_cache/
    └── wandb/                          # W&B logs (synced to cloud)
```

**Checkpoint contents:**
- `agent/` – Policy & Q-network parameters (JAX pytrees)
- `buffer/` – Replay buffer state (optional)
- `env_states/` – Environment RNG states
- `metadata` – Step count, metrics, timestamp

---

## Configuration

### Paper Parameters (from `mt10_mtmhsac.py`)
```python
MTSACConfig(
    num_tasks=10,
    gamma=0.99,
    actor_config=MultiHeadConfig(
        num_tasks=10,
        optimizer=OptimizerConfig(max_grad_norm=1.0)
    ),
    critic_config=QValueFunctionConfig(
        network_config=MultiHeadConfig(num_tasks=10),
    ),
    num_critics=2,
)

OffPolicyTrainingConfig(
    total_steps=20_000_000,    # 20M
    buffer_size=1_000_000,      # 1M
    batch_size=1280,            # Paper default
)
```

### SBATCH Resources
```bash
--partition=a100              # A100 GPU partition
--gres=gpu:1                  # 1 GPU
--cpus-per-task=16            # 16 CPU cores
--mem=64G                     # 64GB RAM
--time=48:00:00               # 48 hours
```

**Estimated runtime:** ~36-42 hours on A100 for 20M steps.

---

## W&B Logging

Metrics logged:
- `train/actor_loss`, `train/critic_loss`, `train/alpha_loss`
- `train/alpha` (entropy coefficient)
- `eval/mean_success_rate` (average across 10 tasks)
- `eval/mean_return`
- `eval/{task_name}_success_rate` (per-task)
- `system/fps`, `system/steps_per_second`

Artifacts:
- `{run_id}_final_agent_checkpoint` – Last checkpoint
- `{run_id}_best_agent_checkpoint` – Best by success rate

View runs at: `https://wandb.ai/{user}/mtrl-mt10/`

---

## Troubleshooting

### Container not found
```bash
# Verify container exists
ls -lh /share/$USER/containers/mtrl.sif

# If missing, upload again
scp mtrl.sif $USER@datalab:/share/$USER/containers/
```

### W&B offline mode
If `WANDB_API_KEY` not set:
```bash
# Job will run in offline mode (logs saved locally)
# Sync later:
cd ~/metaworld_project/wandb_cache/wandb
wandb sync <run_dir>
```

### Out of memory
```bash
# Reduce batch size (edit mt10_mtmhsac.py):
batch_size=640  # Instead of 1280

# Or reduce XLA memory fraction (edit train_mt10_a100_20m.sh):
export SINGULARITYENV_XLA_PYTHON_CLIENT_MEM_FRACTION="0.7"
```

### Job killed (OOM or timeout)
```bash
# Check logs
tail -100 ~/metaworld_project/logs/mt10_sac_20m_<jobid>.err

# If timeout, increase time limit:
#SBATCH --time=72:00:00  # 72 hours

# If OOM, request more memory:
#SBATCH --mem=96G
```

---

## Citation

If you use this script or the MTRL codebase:

```bibtex
@article{mclean2025mtrl,
    title   = {Multi-Task RL Enables Parameter Scaling},
    author  = {McLean, Alexander and Farquhar, Gregor and Henderson, Peter and Amos, Brandon},
    journal = {arXiv preprint arXiv:2503.05126},
    year    = {2025}
}
```

---

## Quick Reference

```bash
# Upload to cluster
./deploy_to_cluster.sh e11704784

# On cluster: set W&B key
export WANDB_API_KEY="..."

# Submit job
cd ~/metaworld_project/source/mtrl
sbatch --export=WANDB_API_KEY=$WANDB_API_KEY docker/cluster/train_mt10_a100_20m.sh

# Monitor
squeue -u $USER
tail -f ~/metaworld_project/logs/mt10_sac_20m_*.log

# Check results
ls ~/metaworld_project/results/mt10_sac_*/checkpoints/

# View on W&B
https://wandb.ai/$USER/mtrl-mt10/
```
