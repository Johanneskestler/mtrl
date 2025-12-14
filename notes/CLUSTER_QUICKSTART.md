# 🚀 MTRL Cluster Quick Start Cheatsheet

## Setup (einmalig, ~30 min)

```bash
# 1. Build Docker Image (lokal)
cd /path/to/mtrl
bash docker/cluster/build_docker.sh
# → Warte 10-15 min

# 2. Konvertiere zu Singularity (lokal)
bash docker/cluster/convert_to_singularity.sh
# → Warte 10-20 min, Output: mtrl.sif (~15GB)

# 3. Upload zu Cluster
bash docker/cluster/upload_code_to_cluster.sh e11704784
# → Warte 10-15 min für .sif upload
```

## Cluster Setup (einmalig)

```bash
# SSH Zugang
ssh e11704784@datalab

# W&B einrichten
bash ~/mtrl_project/source/mtrl/docker/cluster/setup_wandb.sh
# Gib deine W&B API Key ein (von https://wandb.ai/authorize)
```

## Training starten

### Option A: Quick Test (15-20 min)
```bash
ssh e11704784@datalab
sbatch ~/mtrl_project/source/mtrl/docker/cluster/train_mt10_test.sh

# Status checken
squeue -u e11704784
tail -f ~/mtrl_project/logs/slurm_*.log
```

### Option B: Volles Training (8-12 Stunden)
```bash
sbatch ~/mtrl_project/source/mtrl/docker/cluster/train_mt10_full.sh
```

### Option C: Custom Run
```bash
# Edit script
nano ~/mtrl_project/source/mtrl/docker/cluster/train_mt10_test.sh

# Change experiment-name, seed, etc.
# Dann submit
sbatch ~/mtrl_project/source/mtrl/docker/cluster/train_mt10_test.sh
```

## Monitoring

```bash
# Job Status
squeue -u e11704784                    # Liste alle Jobs
scontrol show job <JOB_ID>             # Details für Job

# Logs
tail -f ~/mtrl_project/logs/slurm_*.log    # Live log
grep ERROR ~/mtrl_project/logs/*.log       # Errors suchen

# GPU Usage (während Job läuft)
ssh <NODE>      # Node name aus squeue
nvidia-smi

# W&B Dashboard
https://wandb.ai/Robot_learning_2025/Robot_learning_2025
```

## Ergebnisse runterladen

```bash
# Von lokalem PC:

# Models
rsync -avP e11704784@datalab:~/mtrl_project/models/ ./models_cluster/

# Logs
rsync -avP e11704784@datalab:~/mtrl_project/logs/ ./logs_cluster/

# W&B data
rsync -avP e11704784@datalab:~/mtrl_project/wandb_cache/ ./wandb_cluster/
cd wandb_cluster && wandb sync wandb/run-*
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "Permission denied" | `chmod +x *.sh` |
| "Singularity not found" | Datei nochmal via scp hochladen |
| "W&B login fails" | `bash setup_wandb.sh` erneut |
| "Job pending" | `sinfo` prüfen, Cluster busy? |
| "CUDA not available" | `--nv` Flag in Script prüfen |
| "Out of memory" | Batch size reduzieren |

## Wichtige Pfade

| Typ | Pfad |
|-----|------|
| Singularity Image | `~/mtrl.sif` |
| Project Root | `~/mtrl_project/` |
| Logs | `~/mtrl_project/logs/` |
| Models | `~/mtrl_project/models/` |
| Source Code | `~/mtrl_project/source/mtrl/` |
| W&B Cache | `~/mtrl_project/wandb_cache/` |

## Performance Expectations

| Task | Zeit | GPU Memory |
|------|------|-----------|
| Quick Test (100k) | 15-20 min | ~4GB |
| Full Training (2M) | 8-12h | ~12GB |

## Code Changes Einfügen

```bash
# Nach Code-Änderungen:

# 1. Lokal committen
git add <files>
git commit -m "feat: add feature"
git push origin feature-branch

# 2. Upload Code (SIF bleibt gleich!)
bash docker/cluster/upload_code_to_cluster.sh e11704784

# 3. SBATCH erneut starten
sbatch train_mt10_test.sh
```

---

**Letzte aktualisierung:** 14.12.2025
