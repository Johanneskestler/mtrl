#!/bin/bash
# Git Commit and Push Script
# Commits all cluster deployment changes with proper citation

set -e

echo "=========================================="
echo "Committing Cluster Deployment Changes"
echo "=========================================="
echo ""

# Check git status
git status

echo ""
echo "Ready to commit? This will:"
echo "  - Stage all changes"
echo "  - Commit with comprehensive message"
echo "  - Include proper attribution to original paper"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

echo ""
echo "Staging changes..."
git add .

echo "Creating commit..."
git commit -m "feat: Add Singularity & SLURM cluster deployment infrastructure

## Overview
Add complete cluster deployment pipeline for MTRL (Multi-Task RL) on GPU clusters.
Enables training on TU Wien DataLAB with GPU acceleration and W&B tracking.

## Changes

### Container & Build
- Add Dockerfile with PyTorch GPU + JAX + MuJoCo + OSMesa support
- Add requirements.txt with all Python dependencies
- Add .dockerignore for optimized Docker build context

### Build & Deployment Scripts
- docker/cluster/build_docker.sh: Build Docker image locally
- docker/cluster/convert_to_singularity.sh: Convert Docker → Singularity (.sif)
- docker/cluster/upload_code_to_cluster.sh: Automated upload to cluster
- docker/cluster/setup_wandb.sh: W&B authentication setup
- docker/cluster/run_singularity.sh: Universal Singularity runner

### SLURM Job Scripts
- docker/cluster/train_mt10_test.sh: Quick test job (100k steps, 15-20 min)
- docker/cluster/train_mt10_full.sh: Full training (2M steps, 8-12 hours)

### Monitoring & Logging
- mtrl/monitoring/wandb_logger.py: Enhanced W&B logging module
  * Tracks training metrics (losses, rewards)
  * Per-task performance monitoring
  * Network architecture statistics
  * System resource monitoring (GPU, CPU, memory)
  * Checkpoint artifact saving

### Configuration
- configs/cluster/wandb_config.ini: W&B configuration template
- .env.example: Environment variables template

### Documentation
- CLUSTER_README.md: Comprehensive deployment guide (English)
- CLUSTER_DEPLOYMENT_GUIDE.md: Step-by-step instructions (German)
- CLUSTER_QUICKSTART.md: Quick reference cheatsheet (German)
- CLUSTER_SETUP_SUMMARY.md: Summary of all components
- 00_BITTE_ZUERST_LESEN.md: Getting started guide (German)

## Attribution

This work is based on the original MTRL repository:
  - Repository: https://github.com/rainx0r/mtrl
  - Author: rainx0r
  - Paper: Multi-Task Reinforcement Learning Enables Parameter Scaling
    McLean et al. (2025)
    https://arxiv.org/abs/2503.05126

The cluster deployment infrastructure is an addition to the original work
and does not modify core MTRL algorithms or training procedures.

## Citation

If you use this code, please cite the original paper:

@misc{mclean2025multitaskreinforcementlearningenables,
  title={Multi-Task Reinforcement Learning Enables Parameter Scaling},
  author={Reginald McLean and Evangelos Chatzaroulas and Jordan Terry and 
          Isaac Woungang and Nariman Farsad and Pablo Samuel Castro},
  year={2025},
  eprint={2503.05126},
  archivePrefix={arXiv},
  primaryClass={cs.LG},
  url={https://arxiv.org/abs/2503.05126}
}

## Implementation Notes

- No modifications to core MTRL training code
- W&B logger is optional and non-invasive
- All cluster scripts are separate from core functionality
- Original experiment.py already supports W&B (via wandb.init)
- Fully backward compatible with original MTRL

## Testing

- Docker image builds successfully on local machine
- Singularity conversion works with Apptainer 1.0+
- SLURM scripts tested on TU Wien DataLAB cluster
- W&B integration tested locally and on cluster
- All documentation is comprehensive and tested

## Related Issues

This addresses the need for:
- Reproducible cluster-based RL training
- Comprehensive experiment tracking via W&B
- Easy deployment on GPU clusters using containers
- Reproducible results for paper validation

---

This commit is part of the cluster deployment feature branch.
To merge to main, all tests should pass and documentation should be reviewed.
"

echo ""
echo "✅ Commit successful!"
echo ""
echo "Next step: Push to your fork"
echo "  git push -u origin feature/cluster-deployment"
echo ""
