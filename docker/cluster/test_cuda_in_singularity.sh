#!/bin/bash
#SBATCH --job-name=test_cuda
#SBATCH --partition=GPU-l40s
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=00:05:00
#SBATCH --output=/home/e11704784/test_cuda_singularity_%j.log

echo "=== HOST ===" echo "CUDA_VISIBLE_DEVICES on host: $CUDA_VISIBLE_DEVICES"
nvidia-smi

echo ""
echo "=== IN SINGULARITY WITHOUT --env ==="
singularity exec --nv /share/e11704784/containers/mtrl.sif bash -c '
    echo "CUDA_VISIBLE_DEVICES in container: $CUDA_VISIBLE_DEVICES"
    python -c "import jax; print(f\"JAX devices: {jax.devices()}\")"
'

echo ""
echo "=== IN SINGULARITY WITH --env CUDA_VISIBLE_DEVICES ===" 
singularity exec --nv --env CUDA_VISIBLE_DEVICES="$CUDA_VISIBLE_DEVICES" /share/e11704784/containers/mtrl.sif bash -c '
    echo "CUDA_VISIBLE_DEVICES in container: $CUDA_VISIBLE_DEVICES"
    python -c "import jax; print(f\"JAX devices: {jax.devices()}\")"
'
