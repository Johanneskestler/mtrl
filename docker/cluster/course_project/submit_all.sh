#!/bin/bash
# Convenience script to submit all course project experiments
# Usage: ./submit_all.sh [seed]

SEED="${1:-1}"

echo "=========================================="
echo "Submitting Course Project Experiments"
echo "=========================================="
echo "Seed: $SEED"
echo ""

# Make scripts executable
chmod +x train_reach.sh
chmod +x train_push.sh
chmod +x train_pickplace.sh
chmod +x train_mt3.sh

# Submit single-task experiments
echo "📤 Submitting Single-Task SAC experiments..."
echo ""

echo "  → REACH (target: >90% success rate)"
REACH_JOB=$(sbatch --export=SEED=$SEED train_reach.sh | awk '{print $4}')
echo "     Job ID: $REACH_JOB"

echo "  → PUSH (target: >30% success rate)"
PUSH_JOB=$(sbatch --export=SEED=$SEED train_push.sh | awk '{print $4}')
echo "     Job ID: $PUSH_JOB"

echo "  → PICK-PLACE (target: >30% success rate)"
PICKPLACE_JOB=$(sbatch --export=SEED=$SEED train_pickplace.sh | awk '{print $4}')
echo "     Job ID: $PICKPLACE_JOB"

echo ""
echo "📤 Submitting Multi-Task MTMHSAC experiment..."
echo ""

echo "  → MT3: reach+push+pick-place (target: >40% avg success rate)"
MT3_JOB=$(sbatch --export=SEED=$SEED train_mt3.sh | awk '{print $4}')
echo "     Job ID: $MT3_JOB"

echo ""
echo "=========================================="
echo "All experiments submitted!"
echo "=========================================="
echo ""
echo "Job Summary:"
echo "  - REACH:      $REACH_JOB"
echo "  - PUSH:       $PUSH_JOB"
echo "  - PICK-PLACE: $PICKPLACE_JOB"
echo "  - MT3:        $MT3_JOB"
echo ""
echo "Monitor jobs with: squeue -u \$USER"
echo "View logs in:      ~/mtrl_project/logs/"
echo "View results on:   https://wandb.ai"
echo "=========================================="
