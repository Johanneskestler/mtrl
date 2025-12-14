# ✅ MTRL Cluster Training - Deployment Checklist

## 🔍 Pre-Deployment Check

- [ ] Git setup complete (`git remote -v` zeigt origin, upstream, team)
- [ ] README.md mit Citation vorhanden
- [ ] Alle Files committed: `git status` zeigt "working tree clean"
- [ ] Latest changes gepusht: `git push origin dev-johannes-mtrl-cluster`
- [ ] Docker installiert: `docker --version`
- [ ] Singularity/Apptainer verfügbar: `singularity --version` oder `apptainer --version`
- [ ] SSH zum Cluster funktioniert: `ssh e11704784@datalab echo 'OK'`

---

## 🏗️ Phase 1: Local Build & Test (20-30 min)

### Step 1: Build Docker
```bash
# Option A: Mit Script
bash docker/cluster/build_docker.sh

# Option B: Manual
docker build -t mtrl:latest -f Dockerfile .
```

Check:
```bash
docker images | grep mtrl
# Sollte zeigen: mtrl  latest  ... XX GB
```

**Checkpoint:**
- [ ] `docker images` zeigt `mtrl:latest`

### Step 2: Test Docker locally
```bash
bash docker/cluster/test_docker_local.sh
```

**Expected Output:**
```
========================================
✅ All tests passed!
========================================

Ready to deploy to cluster!
Next: bash deploy_to_cluster.sh e11704784
```

**Checkpoint:**
- [ ] Tests zeigen ✅ passed
- [ ] GPU erkannt: `CUDA available: True`
- [ ] MT10 loaded successfully
- [ ] W&B logger works

---

## 📦 Phase 2: Convert & Upload (30-60 min)

### Step 3: Full Deployment Pipeline
```bash
bash deploy_to_cluster.sh e11704784
```

Was passiert:
1. Docker build (falls nicht vorhanden)
2. Singularity conversion → `mtrl.sif` (~15 GB)
3. Code upload → `/home/e11704784/metaworld_project/source/mtrl/`
4. Container upload → `/home/e11704784/metaworld_project/mtrl.sif`
5. SBATCH script ready

**Checkpoint:**
- [ ] Script läuft ohne Fehler
- [ ] "✅ Deployment Complete!" Message
- [ ] SSH zum Cluster funktioniert

### Step 4: Verify on Cluster
```bash
ssh e11704784@datalab

# Check directories
ls -la /home/e11704784/metaworld_project/
# Sollte zeigen: logs/ models/ wandb_cache/ source/ mtrl.sif

# Check code
ls -la /home/e11704784/metaworld_project/source/mtrl/
# Sollte zeigen: Dockerfile, docker/, mtrl/, requirements.txt, etc.

# Check container
ls -lh /home/e11704784/metaworld_project/mtrl.sif
# Sollte zeigen: -rw-r-- ... 15G ... mtrl.sif
```

**Checkpoint:**
- [ ] `/home/e11704784/metaworld_project/` struktur korrekt
- [ ] `mtrl.sif` vorhanden (15 GB)
- [ ] `source/mtrl/` enthält Code

---

## 🔐 Phase 3: W&B Setup (5 min)

### Step 5: Configure W&B API Key
```bash
ssh e11704784@datalab
cd /home/e11704784/metaworld_project

# Option A: Hol dein API Key
# https://wandb.ai/authorize → "Create new token"

# Option B: Setze ihn (Choice 1)
export WANDB_API_KEY='dein-api-key-hier'

# Option C: Oder lass es offline (Choice 2)
# W&B speichert lokal, sync nach dem Training
```

### Step 6: Test W&B
```bash
# Am Cluster
singularity exec --nv /home/e11704784/metaworld_project/mtrl.sif \
    python -c "import wandb; print('✓ W&B OK')"
```

**Checkpoint:**
- [ ] W&B import funktioniert
- [ ] API Key gesetzt oder Offline-Mode accepted

---

## 🚀 Phase 4: Launch Training (2 min setup)

### Step 7: Submit Training Job
```bash
ssh e11704784@datalab
cd /home/e11704784/metaworld_project/source/mtrl

sbatch docker/cluster/train_mt10_sac_simple.sh
```

**Output:** 
```
Submitted batch job 12345
```

**Checkpoint:**
- [ ] Job ID returned
- [ ] `squeue -u e11704784` zeigt Job

### Step 8: Monitor Training
```bash
# Check status
squeue -u e11704784

# Watch logs in real-time
tail -f /home/e11704784/metaworld_project/logs/mt10_sac_simple_*.log

# Check GPU usage
ssh e11704784@datalab "nvidia-smi"
```

**Expected Log Output:**
```
==========================================
MTRL SAC Training - Simple Architecture
==========================================
Job ID:       12345
GPU:          A40
Time:         2025-12-14 ...
Project Dir:  /home/e11704784/metaworld_project
==========================================

Step 50000/2000000 - Eval metrics: {...}
Saved checkpoint: /home/e11704784/metaworld_project/models/mt10_sac_simple_12345/checkpoint_100000.pt
...
```

**Checkpoint:**
- [ ] Logs zeigen Training-Schritte
- [ ] GPU utilization > 80%
- [ ] Keine CUDA Errors

---

## 📊 Phase 5: Monitor Results (während Training)

### Step 9: Check W&B Dashboard
```
https://wandb.ai/e11704784/mtrl-cluster
```

**Expected Metrics:**
- `Episode Return` (sollte über Zeit steigen)
- `Success Rate` (sollte über Zeit steigen)
- `Policy Loss` (sollte sinken)
- `GPU Memory` (sollte stabil sein)

**Checkpoint:**
- [ ] W&B Dashboard zeigt Runs
- [ ] Metriken werden geloggt
- [ ] Return steigt über Zeit

### Step 10: Check Checkpoints
```bash
ssh e11704784@datalab
ls -lh /home/e11704784/metaworld_project/models/mt10_sac_simple_*/

# Sollte zeigen:
# checkpoint_100000.pt (500 MB)
# checkpoint_200000.pt (500 MB)
# ...
# final_model.pt (500 MB)
```

**Checkpoint:**
- [ ] Checkpoints werden gespeichert
- [ ] Dateigröße ~500 MB pro Checkpoint

---

## ✅ Final Status

After ~8-12 hours of training:

```bash
# Final results
ssh e11704784@datalab
ls /home/e11704784/metaworld_project/models/mt10_sac_simple_*/final_model.pt

# W&B Results
https://wandb.ai/e11704784/mtrl-cluster/runs/<RUN_ID>
```

**Expected Final Metrics (MT10):**
- Final Episode Return: 40-60 (MT10 average)
- Success Rate: 30-50%
- Training stable (no spikes)

**Checkpoint:**
- [ ] Training beendet ohne Errors
- [ ] `final_model.pt` vorhanden
- [ ] W&B Run completed
- [ ] Alle Checkpoints gespeichert

---

## 🎓 Optional: Next Steps

### Download Final Model
```bash
scp e11704784@datalab:/home/e11704784/metaworld_project/models/mt10_sac_simple_*/final_model.pt ./my_model.pt
```

### Train Other Architectures
Modifiziere `train_mt10_sac_simple.sh`:
- Change `network_architecture='simple'` to:
  - `'multi_head'` (separate heads pro task)
  - `'soft_modules'` (adapter networks)
  - `'paco'` (parameter efficient)

### Try MT50
```bash
# In SBATCH script:
NUM_TASKS=50
# And change job name to reflect MT50
```

### Optimize Hyperparameters
Edit in `train_mt10_sac_simple.sh`:
- `TOTAL_STEPS`: Duration
- `EVAL_FREQ`: Checkpoint frequency
- `batch_size`: Memory/Performance tradeoff
- `learning_rate`: Training speed

---

## 🆘 Troubleshooting

| Issue | Solution | Checkpoint |
|-------|----------|-----------|
| `connection refused` | SSH key setup, VPN | [ ] SSH works |
| `CUDA out of memory` | Reduce batch_size oder reduce num_tasks | [ ] Check logs |
| `mtrl.sif not found` | Run `deploy_to_cluster.sh` again | [ ] Container exists |
| `W&B offline` | Normal if no internet; will sync later | [ ] Offline OK |
| `job stuck` | `scancel <JOB_ID>` und check logs | [ ] Job abgebrochen |
| `low GPU usage` | Check container logs, verify GPU binding | [ ] GPU monitoring |

---

## 📝 Success Criteria

✅ **Training erfolgreich wenn:**

1. Docker build → keine Errors
2. Local test → all passed ✓
3. Upload → connection OK ✓
4. W&B → metrics logged ✓
5. Training → steps increase, no crashes
6. Final model → `final_model.pt` exists
7. W&B results → return curve smooth & increasing

---

**Status: READY FOR DEPLOYMENT** 🚀

```bash
# Start now:
bash docker/cluster/test_docker_local.sh
# Then:
bash deploy_to_cluster.sh e11704784
# Then SSH:
ssh e11704784@datalab
cd /home/e11704784/metaworld_project/source/mtrl
sbatch docker/cluster/train_mt10_sac_simple.sh
```

---

**Timeline:**
- Lokal bauen & testen: 20-30 min
- Auf Cluster hochladen: 30-60 min
- Training MT10: 8-12 hours
- **Total: ~9-13 Stunden bis Ergebnisse**

Viel Erfolg! 🎓
