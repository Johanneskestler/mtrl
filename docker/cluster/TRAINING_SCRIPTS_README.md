# MTRL Cluster Training Scripts

## Overview
Organized SBATCH scripts for different MT10 experiments. Each script has a descriptive name and generates well-named runs.

---

## Setup (One-time)

### 1. Configure W&B API Key
```bash
# On cluster
cd ~/metaworld_project/source/mtrl
bash docker/cluster/setup_wandb_key.sh
```

This saves your W&B API key to `~/.wandb_api_key` (permissions 600).  
**No need to use `--export=WANDB_API_KEY` anymore!**

### 2. Verify Setup
```bash
# Quick test (10k steps, ~5 min on A40)
sbatch docker/cluster/mt10_test_10k.sh

# Check status
squeue -u $USER
tail -f ~/metaworld_project/logs/mt10_test_*.log
```

---

## Training Scripts

### 📊 Paper Baseline Experiments

#### Single Seed (Seed 1)
**File:** `mt10_paper_baseline_20M.sh`  
**Run Name:** `mt10_baseline_seed1`  
**Purpose:** Single 20M run with paper parameters

```bash
sbatch docker/cluster/mt10_paper_baseline_20M.sh
```

**Output:**
- Logs: `~/metaworld_project/logs/mt10_baseline_seed1_<jobid>.log`
- Checkpoints: `~/metaworld_project/results/mt10_baseline_seed1_<jobid>/checkpoints/`
- W&B Project: `mtrl-paper-baseline`

---

#### Multi-Seed Array Job (Seeds 1-5)
**File:** `mt10_baseline_multirun.sh`  
**Run Names:** `mt10_baseline_seed1`, `mt10_baseline_seed2`, ..., `mt10_baseline_seed5`  
**Purpose:** Statistical significance (paper reports mean ± std over 5 seeds)

```bash
sbatch docker/cluster/mt10_baseline_multirun.sh
```

This submits **5 parallel jobs** (array job), one per seed.

**Output:**
- Logs: `~/metaworld_project/logs/mt10_baseline_seed{1-5}_<jobid>.log`
- Checkpoints: `~/metaworld_project/results/mt10_baseline_seed{1-5}_<jobid>/`
- W&B Project: `mtrl-paper-baseline` (5 runs grouped)

**Monitor:**
```bash
squeue -u $USER                    # See all 5 jobs
tail -f ~/metaworld_project/logs/mt10_baseline_seed1_*.log  # Watch seed 1
```

---

#### Quick Test (10k steps)
**File:** `mt10_test_10k.sh`  
**Run Name:** `mt10_test_10k`  
**Purpose:** Verify setup before long runs (~5 min on A40)

```bash
sbatch docker/cluster/mt10_test_10k.sh
```

**Output:**
- Logs: `~/metaworld_project/logs/mt10_test_<jobid>.log`
- W&B Project: `mtrl-tests`
- No checkpoints (checkpoint=False for speed)

---

## Script Comparison

| Script | Steps | Seeds | GPU | Time | Run Names |
|--------|-------|-------|-----|------|-----------|
| `mt10_test_10k.sh` | 10k | 1 (seed 42) | A40 | ~5 min | `mt10_test_10k` |
| `mt10_paper_baseline_20M.sh` | 20M | 1 (seed 1) | A100 | ~40-48h | `mt10_baseline_seed1` |
| `mt10_baseline_multirun.sh` | 20M | 5 (seeds 1-5) | A100 | ~40-48h each | `mt10_baseline_seed{1-5}` |

---

## Configuration

All scripts use:
- **Network:** 3x1024 multi-head SAC (paper baseline)
- **Batch size:** 1280
- **Buffer size:** 1M
- **Gamma:** 0.99
- **Checkpoints:** Saved every ~1M steps, best 5 kept

### Hardware Allocation

**A100 Scripts:**
```bash
#SBATCH --partition=GPU-a100
#SBATCH --gres=gpu:a100:1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=48:00:00
```

**A40 Test:**
```bash
#SBATCH --partition=GPU-a40
#SBATCH --gres=gpu:a40:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=00:30:00
```

---

## W&B Projects

| Project | Purpose |
|---------|---------|
| `mtrl-tests` | Quick validation runs |
| `mtrl-paper-baseline` | Paper reproduction experiments |

All runs are tagged with:
- `run_name`: Descriptive name (e.g., `mt10_baseline_seed3`)
- `seed`: Random seed used
- `experiment`: Paper baseline config

---

## Monitoring

### Check Job Status
```bash
# All jobs
squeue -u $USER

# Specific job
squeue -j <jobid>

# Array job
squeue -u $USER | grep mt10_baseline
```

### Watch Logs
```bash
# Live tail
tail -f ~/metaworld_project/logs/mt10_baseline_seed1_*.log

# Last 100 lines
tail -100 ~/metaworld_project/logs/mt10_baseline_seed1_*.log

# Search for errors
grep -i error ~/metaworld_project/logs/mt10_baseline_seed1_*.log
```

### GPU Utilization
```bash
# SSH to compute node
ssh <node-name>

# Watch GPU
watch -n 1 nvidia-smi
```

### W&B Dashboard
```bash
# View runs
https://wandb.ai/e11704784/mtrl-paper-baseline

# Compare seeds
https://wandb.ai/e11704784/mtrl-paper-baseline/table
```

---

## Resume Interrupted Jobs

If a job is killed/crashes, resume from checkpoint:

```bash
# Find last checkpoint
ls ~/metaworld_project/results/mt10_baseline_seed1_<jobid>/checkpoints/

# Edit script: add --resume flag to python command
# Then resubmit
sbatch docker/cluster/mt10_paper_baseline_20M.sh
```

The experiment will auto-detect and resume from the latest checkpoint.

---

## Troubleshooting

### W&B API Key Issues
```bash
# Verify key is saved
cat ~/.wandb_api_key

# Re-run setup if needed
bash docker/cluster/setup_wandb_key.sh
```

### Container Not Found
```bash
# Check container exists
ls -lh /share/e11704784/containers/mtrl.sif

# If missing, upload
scp mtrl.sif e11704784@datalab:/share/e11704784/containers/
```

### Job Killed (OOM)
- Increase `--mem` (e.g., `96G` instead of `64G`)
- Or reduce batch size in experiment config

### Job Timeout
- Increase `--time` (e.g., `72:00:00` for 72 hours)

---

## Adding New Experiments

To create a new experiment script:

1. Copy an existing script:
```bash
cp docker/cluster/mt10_paper_baseline_20M.sh docker/cluster/mt10_your_experiment.sh
```

2. Update:
   - `#SBATCH --job-name=...`
   - `#SBATCH --output=.../logs/your_experiment_%j.log`
   - `RUN_NAME="your_experiment"`
   - `WANDB_PROJECT="your-project"`
   - Python config file or parameters

3. Test first:
```bash
sbatch docker/cluster/mt10_your_experiment.sh
```

---

## Quick Reference

```bash
# Setup (once)
bash docker/cluster/setup_wandb_key.sh

# Test
sbatch docker/cluster/mt10_test_10k.sh

# Single baseline run
sbatch docker/cluster/mt10_paper_baseline_20M.sh

# Multi-seed (5 parallel)
sbatch docker/cluster/mt10_baseline_multirun.sh

# Monitor
squeue -u $USER
tail -f ~/metaworld_project/logs/*.log

# View results
https://wandb.ai/e11704784/mtrl-paper-baseline
```
