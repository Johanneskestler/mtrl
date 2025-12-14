# 🚀 MTRL Cluster Deployment Guide

**Status:** ✅ Ready for DataLAB Cluster  
**Last Updated:** December 14, 2025  
**Target:** TU Wien dataLAB (A40 GPU)

---

## 📋 Quick Start

### Phase 1: Lokale Vorbereitung (5 min)

```bash
cd /path/to/mtrl

# 1. Build Docker Image
bash docker/cluster/build_docker.sh
# Output: mtrl:latest (~15GB)

# 2. Convert to Singularity (10-20 min)
bash docker/cluster/convert_to_singularity.sh
# Output: mtrl.sif (~15GB)

# 3. Test lokales Singularity
apptainer exec --nv mtrl.sif python -c "import metaworld; print('✓ OK')"
```

### Phase 2: Upload zum Cluster (10-15 min)

```bash
# 1. Upload Singularity Image (7-10 GB via rsync)
scp mtrl.sif e11704784@datalab:/home/e11704784/

# 2. Upload Code
bash docker/cluster/upload_code_to_cluster.sh e11704784
```

### Phase 3: Cluster-Setup (SSH)

```bash
ssh e11704784@datalab

# 1. W&B einrichten
bash ~/mtrl_project/source/mtrl/docker/cluster/setup_wandb.sh

# 2. Schnelltest
sbatch ~/mtrl_project/source/mtrl/docker/cluster/train_mt10_test.sh
squeue -u e11704784
tail -f ~/mtrl_project/logs/slurm_*.log
```

---

## 📁 Verzeichnisstruktur

### Lokal
```
mtrl/
├── Dockerfile
├── requirements.txt
├── mtrl.sif (nach convert)
├── docker/cluster/
│   ├── build_docker.sh
│   ├── convert_to_singularity.sh
│   ├── upload_code_to_cluster.sh
│   ├── train_mt10_test.sh
│   ├── train_mt10_full.sh
│   └── setup_wandb.sh
└── experiments/
    └── mt10_mtmhsac.py
```

### Auf Cluster
```
/home/e11704784/
├── mtrl.sif (Singularity image)
└── mtrl_project/
    ├── logs/
    │   ├── slurm_12345.log
    │   └── slurm_12345.err
    ├── models/
    │   └── mt10_test_12345/
    │       ├── checkpoint_100000.pt
    │       └── final_model.pt
    ├── wandb_cache/
    │   └── wandb/run-*/
    └── source/mtrl/ (read-only mount)
        ├── experiments/
        ├── mtrl/
        └── docker/cluster/
```

---

## 🚀 Training starten

### Option 1: Quick Test (15-20 min)
```bash
ssh e11704784@datalab
sbatch ~/mtrl_project/source/mtrl/docker/cluster/train_mt10_test.sh

# Monitor
squeue -u e11704784
tail -f ~/mtrl_project/logs/slurm_*.log
```

### Option 2: Full Training (8-12 Stunden)
```bash
sbatch ~/mtrl_project/source/mtrl/docker/cluster/train_mt10_full.sh
```

### Option 3: Custom Parameters
```bash
# Edit script vorher
nano ~/mtrl_project/source/mtrl/docker/cluster/train_mt10_test.sh

# Change z.B.:
# --experiment-name "custom_name"
# --seed 42

sbatch ~/mtrl_project/source/mtrl/docker/cluster/train_mt10_test.sh
```

---

## 📊 Monitoring

### Job Status
```bash
# Alle deine Jobs
squeue -u e11704784

# Detailliertes Status
scontrol show job <JOB_ID>

# GPU-Nutzung (während Job läuft)
ssh <compute-node>  # aus squeue
nvidia-smi
```

### Logs
```bash
# Live verfolgen
tail -f ~/mtrl_project/logs/slurm_*.log

# Durchsuchen
grep "WARNING\|ERROR" ~/mtrl_project/logs/slurm_*.log

# Nach Abschluss komplettes Log
cat ~/mtrl_project/logs/slurm_12345.log
```

### W&B Dashboard
```
https://wandb.ai/Robot_learning_2025/Robot_learning_2025
```

---

## 💾 Ergebnisse runterladen

```bash
# Von deinem lokalen PC:

# Models
rsync -avP e11704784@datalab:~/mtrl_project/models/ ./models_from_cluster/

# Logs
rsync -avP e11704784@datalab:~/mtrl_project/logs/ ./logs_from_cluster/

# W&B offline sync (auf Cluster zuerst)
ssh e11704784@datalab
cd ~/mtrl_project/wandb_cache
wandb sync wandb/run-*
```

---

## 🔧 Troubleshooting

| Problem | Lösung |
|---------|--------|
| "Permission denied" | `chmod +x *.sh` |
| "Singularity not found" | Scp file nach cluster |
| "W&B login failed" | `bash setup_wandb.sh` erneut |
| "CUDA not available" | Prüfe `--nv` flag im script |
| "Job pending" | Check cluster load: `sinfo` |
| "Out of memory" | Reduce batch size im config |

---

## 📈 Performance Erwartungen

| Task | Zeit | GPU Memory |
|------|------|-----------|
| Quick Test (100k) | 15-20 min | ~4GB |
| Full Training (2M) | 8-12h | ~12GB |
| Evaluation | ~5 min | ~2GB |

---

## 📝 Wichtige Files

| Datei | Zweck |
|-------|-------|
| `Dockerfile` | Container-Spezifikation |
| `requirements.txt` | Python-Dependencies |
| `build_docker.sh` | Lokaler Build |
| `convert_to_singularity.sh` | Docker→SIF Konvertierung |
| `train_mt10_test.sh` | SLURM Test-Job |
| `train_mt10_full.sh` | SLURM Full-Training |
| `upload_code_to_cluster.sh` | Code-Upload |
| `setup_wandb.sh` | W&B Authentifizierung |

---

**Nächste Schritte:**
1. `bash docker/cluster/build_docker.sh`
2. `bash docker/cluster/convert_to_singularity.sh`
3. `bash docker/cluster/upload_code_to_cluster.sh e11704784`
4. `ssh e11704784@datalab` und `bash setup_wandb.sh`
5. `sbatch train_mt10_test.sh`

Viel Erfolg! 🎉
