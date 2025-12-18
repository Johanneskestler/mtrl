# Course Project Cluster Scripts

This directory contains SLURM batch scripts for running the course project experiments on the DataLAB cluster.

## Experiments

### Single-Task SAC
- **reach**: `train_reach.sh` - Target: >90% success rate
- **push**: `train_push.sh` - Target: >30% success rate  
- **pick-place**: `train_pickplace.sh` - Target: >30% success rate

### Multi-Task MTMHSAC
- **MT3**: `train_mt3.sh` - 3-task training (reach+push+pick-place), Target: >40% avg success rate

## Usage

### Prerequisites
1. Ensure you have the Singularity image: `~/mtrl.sif`
2. Set up project directories:
   ```bash
   ssh datalab
   mkdir -p ~/metaworld_project/{logs,models,wandb_cache,source}
   ```
3. Copy your code from local machine:
   ```bash
   # On your local machine
   rsync -avz mtrl/ e11704784@datalab:~/metaworld_project/source/mtrl/
   ```

### Submit Individual Jobs
```bash
# With default seed (1)
sbatch train_reach.sh

# With custom seed
sbatch --export=SEED=42 train_reach.sh
```

### Submit All Jobs at Once
```bash
# With default seed (1)
./submit_all.sh

# With custom seed
./submit_all.sh 42
```

## Job Configuration

All jobs are configured with:
- **GPU**: 1x A40 (40GB VRAM)
- **CPU**: 8 cores
- **RAM**: 32GB
- **Time**: 4 hours (sufficient for 2M steps)
- **Partition**: GPU-a40

## Monitoring

```bash
# Check job status
squeue -u $USER

# View live logs
tail -f ~/metaworld_project/logs/reach_<jobid>.log

# View WandB
# Navigate to: https://wandb.ai/your-entity/mtrl-course-project
```

## Output Locations

- **Logs**: `~/metaworld_project/logs/`
- **Checkpoints**: `~/metaworld_project/models/{reach,push,pickplace,mt3}_seed{N}/`
- **WandB**: Synced to project `mtrl-course-project`

## WandB Run Names

Runs are automatically named for easy identification:
- Single-task: `ST_SAC_{task}_seed{N}`
- Multi-task: `MT3_MTMHSAC_seed{N}`

## Troubleshooting

### Image not found
```bash
# Check if image exists
ls -lh ~/mtrl.sif

# If missing, build it first (see main cluster docs)
```

### Out of memory
```bash
# Increase memory allocation in SBATCH headers:
#SBATCH --mem=64G
```

### Training takes too long
```bash
# Extend time limit:
#SBATCH --time=08:00:00
```

## Architecture Details

### Single-Task SAC
- Network width: 1024 units
- Total training steps: 2M
- Batch size: 128
- Buffer size: 100k

### Multi-Task MTMHSAC
- Shared backbone: 3 layers × 1024 units
- Task-specific heads: 3 (one per task)
- Total training steps: 2M
- Batch size: 384 (128 per task, balanced sampling)
- Buffer size: 300k (100k per task)
