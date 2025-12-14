# MTRL Cluster Extension

This fork packages the original MTRL codebase with a full cluster-ready toolchain (Docker → Singularity, SLURM jobs, and W&B logging) for MT10/MT50 experiments on TU Wien DataLAB. Core learning code remains unchanged; all additions live beside the upstream sources.

## What is included
- Dockerfile with CUDA 12.1, MuJoCo headless rendering, and pinned Python deps.
- Singularity conversion and SLURM submit scripts in `docker/cluster/`.
- Enhanced W&B logger in `mtrl/monitoring/wandb_logger.py`.
- Cluster guides in `notes/` (quickstart, deployment, setup summary, workflow).

## How to use (short)
1) Build locally: `bash docker/cluster/build_docker.sh`
2) Convert to Singularity: `bash docker/cluster/convert_to_singularity.sh`
3) Upload to DataLAB: `bash docker/cluster/upload_code_to_cluster.sh <tuwien-user>`
4) On cluster, run test job: `sbatch docker/cluster/train_mt10_test.sh`
5) Track runs in W&B (configure via `docker/cluster/setup_wandb.sh`).

See `notes/CLUSTER_README.md` and `notes/CLUSTER_QUICKSTART.md` for full instructions.

## Original work and citation
- Original repository: https://github.com/rainx0r/mtrl
- Paper: McLean et al., 2025, "Multi-Task RL Enables Parameter Scaling" (arXiv:2503.05126)

If you use this fork, please cite the paper:

```
@article{mclean2025mtrl,
	title   = {Multi-Task RL Enables Parameter Scaling},
	author  = {McLean, Alexander and Farquhar, Gregor and Henderson, Peter and Amos, Brandon},
	journal = {arXiv preprint arXiv:2503.05126},
	year    = {2025}
}
```

Attribution: this fork adds cluster tooling and logging; learning code and experiments are derived from the upstream authors.
