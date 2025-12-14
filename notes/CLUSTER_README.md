# 🚀 MTRL Cluster Deployment & Training Guide

**Status:** ✅ Production Ready  
**Last Updated:** December 14, 2025  
**Target:** TU Wien DataLAB Cluster (A40 GPU)  
**Original Work:** [rainx0r/mtrl](https://github.com/rainx0r/mtrl)

---

## 📚 Table of Contents

1. [Quick Start](#quick-start) - 30 minutes
2. [Overview](#overview) - Project structure
3. [Citation & Attribution](#citation--attribution) - How to cite
4. [Detailed Setup](#detailed-setup) - Step-by-step
5. [Running Training](#running-training) - Different options
6. [Monitoring & Results](#monitoring--results)
7. [Troubleshooting](#troubleshooting)

---

## ⚡ Quick Start

**Total time:** ~45 minutes (first time setup)

### 1️⃣ Build Container (local, ~15 min)

```bash
cd /path/to/mtrl

# Build Docker image
bash docker/cluster/build_docker.sh

# Convert to Singularity
bash docker/cluster/convert_to_singularity.sh
# → Creates: mtrl.sif (~15GB)
```

### 2️⃣ Upload to Cluster (~15 min)

```bash
# Upload code and image
bash docker/cluster/upload_code_to_cluster.sh e11704784

# Verify
ssh e11704784@datalab
ls -lh ~/mtrl.sif
ls -la ~/mtrl_project/
```

### 3️⃣ Setup W&B (~5 min)

```bash
# On cluster:
bash ~/mtrl_project/source/mtrl/docker/cluster/setup_wandb.sh

# Paste your W&B API Key from https://wandb.ai/authorize
```

### 4️⃣ Start Training (~2 min)

```bash
# Quick test (15-20 min)
sbatch ~/mtrl_project/source/mtrl/docker/cluster/train_mt10_test.sh

# Monitor
squeue -u e11704784
tail -f ~/mtrl_project/logs/slurm_*.log
```

---

## 📊 Overview

### Project Structure

```
mtrl/
├── Dockerfile                          # Container specification
├── requirements.txt                    # Python dependencies
├── .dockerignore                       # Build context exclusions
├── .env.example                        # Configuration template
│
├── docker/cluster/                     # Cluster utilities
│   ├── build_docker.sh                # Build Docker image
│   ├── convert_to_singularity.sh       # Docker → Singularity
│   ├── upload_code_to_cluster.sh       # Upload to cluster
│   ├── setup_wandb.sh                  # W&B authentication
│   ├── run_singularity.sh              # Universal runner
│   ├── train_mt10_test.sh              # Test job script
│   └── train_mt10_full.sh              # Full training script
│
├── configs/cluster/                    # Cluster configurations
│   └── wandb_config.ini                # W&B settings
│
├── mtrl/
│   ├── monitoring/
│   │   ├── wandb_logger.py            # ✨ Enhanced W&B logging
│   │   └── ...
│   ├── experiment.py                   # Main experiment runner
│   └── ...
│
├── experiments/
│   ├── example.py                      # Example experiment
│   ├── mt10_mtmhsac.py                # MT10 SAC training
│   ├── mt50_mtmhsac_v2.py             # MT50 SAC training
│   └── ...
│
├── CLUSTER_DEPLOYMENT_GUIDE.md         # Detailed guide (German)
├── CLUSTER_QUICKSTART.md               # Cheatsheet (German)
└── README.md                           # This file
```

### What's New (vs Original)

✨ **Added for Cluster Support:**
- Dockerfile with headless rendering support
- Docker → Singularity conversion pipeline
- SLURM job scripts (test & full training)
- Enhanced W&B logging system (`wandb_logger.py`)
- Cluster upload & setup scripts
- Comprehensive documentation (German & English)

### Changes from Original

**Minimal invasive changes:**
- ✅ New W&B logger module (doesn't break existing code)
- ✅ Container configuration (not part of core)
- ✅ Job scripts (cluster-specific)
- ⚠️ No modifications to core MTRL training code
- ⚠️ No API changes to existing modules

---

## 📝 Citation & Attribution

### Original Work

This is a **fork and adaptation** of the original MTRL repository:

**Original Repository:**
```
https://github.com/rainx0r/mtrl
Author: rainx0r
```

**Please cite the original paper:**
```bibtex
@article{[see original README for paper citation]}
```

### This Fork

If you use this cluster-adapted version, acknowledge both:

```bibtex
@software{mtrl_fork_cluster,
  author={Johannes},
  title={MTRL Fork - Cluster Adaptation for DataLAB},
  url={https://github.com/<your-fork-url>},
  year={2025},
  note={Fork of https://github.com/rainx0r/mtrl with cluster deployment}
}
```

### How to Properly Credit

1. **In Papers:** Cite both original and fork (see above)
2. **In Code:** Include reference to original repo in comments
3. **In README:** Link to original project
4. **In Commits:** Use commit messages referencing original work

**Example Commit Message:**
```
feat: Add cluster deployment infrastructure

Builds on original rainx0r/mtrl with:
- Singularity containerization
- SLURM job management
- Enhanced W&B logging

Original: https://github.com/rainx0r/mtrl
```

---

## 🔧 Detailed Setup

### Prerequisites

- SSH access to datalab cluster
- Docker installed locally
- Apptainer (Singularity) ≥ 1.0
- W&B account (https://wandb.ai)
- ~25 GB local disk for images
- ~100 GB cluster disk for models/logs

### Step 1: Build Docker Image

```bash
cd /path/to/mtrl

# Make script executable
chmod +x docker/cluster/build_docker.sh

# Build (takes 10-15 minutes)
bash docker/cluster/build_docker.sh
```

**What it does:**
- Starts from pytorch/pytorch:2.3.0-cuda12.1-cudnn8-runtime
- Installs system dependencies (OSMesa for headless rendering)
- Installs Python packages from requirements.txt
- Creates workspace directories
- Validates installation

**Output:**
```
Successfully built mtrl:latest
Size: ~15GB
```

### Step 2: Convert to Singularity

```bash
# Make script executable
chmod +x docker/cluster/convert_to_singularity.sh

# Convert (takes 10-20 minutes)
bash docker/cluster/convert_to_singularity.sh
```

**What it does:**
- Converts Docker → Singularity using apptainer build
- Creates mtrl.sif (~15GB)
- Validates the image

**Output:**
```
mtrl.sif (15GB)
```

**Test locally (optional):**
```bash
apptainer exec --nv mtrl.sif python -c \
  "import torch, metaworld; print('✓ OK')"
```

### Step 3: Upload to Cluster

```bash
# Make script executable
chmod +x docker/cluster/upload_code_to_cluster.sh

# Upload (takes 10-20 minutes for .sif)
bash docker/cluster/upload_code_to_cluster.sh e11704784
```

**Note:** Replace `e11704784` with your TU username

**What it does:**
- Uploads mtrl.sif to cluster
- Uploads source code via rsync
- Creates necessary directories
- Validates upload

**Result on cluster:**
```
~/mtrl.sif                              # 15GB
~/mtrl_project/source/mtrl/             # Full codebase
~/mtrl_project/{logs,models,wandb_cache}/  # Empty but ready
```

### Step 4: Setup W&B on Cluster

```bash
# SSH to cluster
ssh e11704784@datalab

# Run setup script
bash ~/mtrl_project/source/mtrl/docker/cluster/setup_wandb.sh

# When prompted, paste your W&B API Key:
# Get it from: https://wandb.ai/authorize
```

**Verification:**
```bash
# Should show "already logged in"
wandb status
```

---

## 🏋️ Running Training

### Option 1: Quick Test (15-20 min)

Good for validating setup before long runs.

```bash
sbatch ~/mtrl_project/source/mtrl/docker/cluster/train_mt10_test.sh

# Monitor
squeue -u e11704784
tail -f ~/mtrl_project/logs/slurm_*.log

# Expected output:
# ✅ Job completes after ~15-20 minutes
# ✅ Models saved to ~/mtrl_project/models/mt10_test_*/
# ✅ W&B run visible at https://wandb.ai/...
```

### Option 2: Full Training (8-12 hours)

```bash
sbatch ~/mtrl_project/source/mtrl/docker/cluster/train_mt10_full.sh

# Check status
squeue -u e11704784

# Expected:
# - Job runs for 8-12 hours
# - Checkpoints saved every 100k steps
# - W&B logs in real-time
```

### Option 3: Custom Configuration

Edit script and customize:

```bash
# Edit the script
nano ~/mtrl_project/source/mtrl/docker/cluster/train_mt10_test.sh

# Change these lines:
#SBATCH --job-name=mtrl_custom
#SBATCH --time=02:00:00

# Add custom experiment name:
python experiments/mt10_mtmhsac.py \
    --experiment-name "my_custom_run" \
    --seed 42 \
    --track

# Submit
sbatch train_mt10_test.sh
```

### Option 4: Multiple Parallel Runs

```bash
# Submit multiple jobs with different seeds
for seed in 1 2 3 4 5; do
    SEED=$seed sbatch train_mt10_test.sh
    sleep 10  # Avoid race conditions
done

# Monitor all
squeue -u e11704784
```

---

## 📊 Monitoring & Results

### Job Monitoring

```bash
# See all your jobs
squeue -u e11704784

# Detailed job info
scontrol show job <JOB_ID>

# Cancel a job
scancel <JOB_ID>

# Job history
sacct -u e11704784 --format=JobID,JobName,State,Elapsed
```

### Log Files

```bash
# Live monitoring
tail -f ~/mtrl_project/logs/slurm_*.log

# Search for errors
grep ERROR ~/mtrl_project/logs/*.log
grep WARN ~/mtrl_project/logs/*.log

# Full log inspection
cat ~/mtrl_project/logs/slurm_12345.log
```

### GPU Monitoring

```bash
# GPU stats (while job running)
ssh <compute-node-name>  # Get from squeue
nvidia-smi

# Continuous monitoring
watch -n 2 nvidia-smi
```

### W&B Dashboard

```
https://wandb.ai/Robot_learning_2025/Robot_learning_2025
```

**View:**
- Training loss curves
- Per-task success rates
- Network parameter counts
- System resource usage
- Checkpoints and artifacts

### Download Results

```bash
# On your local PC:

# Models (~500MB per checkpoint)
rsync -avP e11704784@datalab:~/mtrl_project/models/ ./models_from_cluster/

# Logs (~1MB)
rsync -avP e11704784@datalab:~/mtrl_project/logs/ ./logs_from_cluster/

# W&B offline sync (if using offline mode)
rsync -avP e11704784@datalab:~/mtrl_project/wandb_cache/ ./wandb_from_cluster/
cd wandb_from_cluster && wandb sync wandb/run-*
```

---

## 🐛 Troubleshooting

### Common Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| "Permission denied" | Scripts not executable | `chmod +x *.sh` |
| "Singularity not found" | File not uploaded | `scp mtrl.sif user@datalab:~` |
| "CUDA not available" | Missing --nv flag | Check train_mt10_test.sh |
| "W&B login failed" | Missing API key | Run `bash setup_wandb.sh` again |
| "Job pending" | Cluster busy | Check `sinfo`, wait or try later |
| "Out of memory" | GPU memory exceeded | Reduce batch_size in config |
| "Mount target doesn't exist" | Bad bind path | Check directories exist in container |

### Validation Checks

```bash
# Verify Singularity image
apptainer exec --nv mtrl.sif python --version

# Verify code upload
ssh e11704784@datalab "ls ~/mtrl_project/source/mtrl/experiments/"

# Verify W&B
ssh e11704784@datalab "wandb status"

# Verify GPU partition
ssh e11704784@datalab "sinfo -p GPU-a40"
```

---

## 📈 Performance Expectations

| Metric | Value |
|--------|-------|
| **Quick Test (100k steps)** | 15-20 min |
| **Full Training (2M steps)** | 8-12 hours |
| **GPU Memory Usage** | ~12GB (A40) |
| **Models per checkpoint** | ~500MB |
| **Logs (full training)** | ~5MB |
| **W&B artifacts** | ~1GB per run |

---

## 🔄 Development Workflow

### Making Code Changes

```bash
# 1. Make changes locally
vim experiments/mt10_mtmhsac.py

# 2. Test locally (optional)
python experiments/mt10_mtmhsac.py --help

# 3. Commit to git
git add experiments/mt10_mtmhsac.py
git commit -m "feat: modify MT10 config"
git push origin feature-branch

# 4. Upload to cluster (SIF doesn't change!)
bash docker/cluster/upload_code_to_cluster.sh e11704784

# 5. Run training
ssh e11704784@datalab
sbatch ~/mtrl_project/source/mtrl/docker/cluster/train_mt10_test.sh
```

### Only Rebuilding Container

If you modify Dockerfile or requirements.txt:

```bash
# Local
bash docker/cluster/build_docker.sh
bash docker/cluster/convert_to_singularity.sh

# Upload new image
scp mtrl.sif e11704784@datalab:~/mtrl.sif

# Then re-run jobs
```

---

## 📚 Further Resources

- **Original MTRL:** https://github.com/rainx0r/mtrl
- **W&B Documentation:** https://docs.wandb.ai/
- **SLURM Documentation:** https://slurm.schedmd.com/
- **Apptainer Documentation:** https://apptainer.org/docs/

---

## 📞 Support

For issues:
1. Check [Troubleshooting](#troubleshooting) section
2. Review logs in `~/mtrl_project/logs/`
3. Check W&B dashboard for training metrics
4. Consult original MTRL repository

---

## ✅ Checklist

### Before Training

- [ ] Docker image built (`mtrl:latest`)
- [ ] Singularity converted (`mtrl.sif`)
- [ ] Code uploaded to cluster
- [ ] W&B API key configured
- [ ] Test job completed successfully

### During Training

- [ ] Monitor via `squeue -u <user>`
- [ ] Check logs with `tail -f`
- [ ] Watch W&B dashboard
- [ ] Verify GPU usage with `nvidia-smi`

### After Training

- [ ] Download models and logs
- [ ] Review W&B artifacts
- [ ] Archive results
- [ ] Cleanup cluster disk space

---

**Happy training! 🚀**

*This guide was created to help deploy the MTRL repository on the TU Wien DataLAB cluster while maintaining proper attribution to the original authors.*
