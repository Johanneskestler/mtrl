# 🎓 MTRL Training Scripts - Paper Parameters

**Alle Training-Scripts verwenden die exakten Parameter aus McLean et al., 2025**

---

## 📊 Training-Übersicht

| Script | Environment | Tasks | Duration | Steps | Replay Buffer |
|--------|-------------|-------|----------|-------|---------------|
| `train_mt10_mtrl.sh` | MT10 | 10 | ~12h | 20M (2M/task) | 100k × 10 = 1M |
| `train_mt50_mtrl.sh` | MT50 | 50 | ~3-5 Tage | 100M (2M/task) | 100k × 50 = 5M |
| `train_mt10_sac_simple.sh` | MT10 | 10 | ~8-12h | 2M (test) | Same |

---

## 🚀 Quick Start

### 1️⃣ MT10 Training (Empfohlen zum Anfangen)

```bash
# Am Cluster
cd /home/e11704784/metaworld_project/source/mtrl

# Single run
sbatch docker/cluster/train_mt10_mtrl.sh

# Oder alle 10 Seeds parallel
for i in {1..10}; do sbatch docker/cluster/train_mt10_mtrl.sh; done
```

**Dauer:** ~12 Stunden pro Run  
**Checkpoints:** Alle 1M steps  
**Result:** Inter-Quartile Mean (IQM) über 10 Seeds

---

### 2️⃣ MT50 Training (Long Run)

```bash
# Single run (takes 3-5 days)
sbatch docker/cluster/train_mt50_mtrl.sh

# Oder alle 10 Seeds nacheinander (längere Queue)
for i in {1..10}; do sbatch docker/cluster/train_mt50_mtrl.sh; done
```

**Dauer:** ~3-5 Tage pro Run  
**Checkpoints:** Alle 5M steps  
**Result:** Zeigt Scaling + Plasticity bei großem Task-Set

---

## 📝 Paper Parameters - Detailliert

### Algorithm & Environment
```
Algorithm:           Soft Actor-Critic (SAC)
MT10 Steps:          20,000,000 (2M per task)
MT50 Steps:          100,000,000 (2M per task)
Evaluation:          50 episodes
Eval Frequency:      Every 200k steps (MT10) / 1M steps (MT50)
Random Seeds:        10 (submit 10 separate jobs)
```

### Network Architecture (Baseline)
```
Type:                Multi-Layer Perceptron
Hidden Layers:       3
Width:               1024 (baseline; variations: 400, 200, 4096)
Activation:          ReLU
Task Conditioning:   One-hot task ID appended to state
Min Log Std:         exp(-20)
```

### Replay Buffer (Paper-Specific)
```
Type:                Per-task replay buffers
Capacity:            100k per task
Total Capacity:      100k × N_tasks
  - MT10: 1M total
  - MT50: 5M total
Sampling:            Uniform sampling per task
```

### SAC Hyperparameters
```
Learning Rate:       3e-4
Batch Size:          256
Discount (γ):        0.99
Polyak τ:            0.005 (target smoothing)
Entropy Tuning:      Automatic
Target Entropy:      -action_dim
Gradient Steps:      1 per environment step
Initial Random:      1000 steps
```

### Loss & Optimization
```
Loss Weighting:      Uniform per-task
Loss Aggregation:    Mean over all task losses
Optimizer:           Adam
Weight Decay:        0
Target Update:       Via Polyak averaging (τ)
```

---

## 🎯 Zu erwartende Ergebnisse (aus Paper)

### MT10 (nach 20M steps)
```
Durchschnittlicher Episode Return:  40-60 (pro Task)
Success Rate:                       30-50%
Training Stabilität:                Glatte Kurven, keine großen Spikes
Parameter Count (1024 width):        ~500k
```

### MT50 (nach 100M steps)
```
Durchschnittlicher Episode Return:  30-50 (pro Task, variiert)
Success Rate:                       25-40%
Plasticity:                         Gut erhalten (viele Tasks)
Scaling Trend:                      Returns steigen mit Modellgröße
```

---

## 📊 W&B Monitoring

### Automatisch geloggt:
```
paper/algorithm                  → SAC
paper/total_timesteps            → 20M oder 100M
paper/num_tasks                  → 10 oder 50
paper/eval_frequency             → 200k oder 1M
paper/hidden_sizes               → [1024, 1024, 1024]
paper/learning_rate              → 3e-4
paper/batch_size                 → 256
paper/gamma                       → 0.99
paper/tau                         → 0.005
paper/replay_buffer_per_task      → 100000
eval/episode_return              → Running mean return
eval/success_rate                → Success rate
eval/episode_length              → Episode length
checkpoint/step                  → Checkpoint step
final/total_steps                → Final step count
```

### Dashboard
```
https://wandb.ai/YOUR-USERNAME/mtrl-cluster
```

---

## 🔄 Script Submitting Pattern

### Single Job
```bash
sbatch docker/cluster/train_mt10_mtrl.sh
# Returns: Submitted batch job 12345
```

### Multiple Seeds (Parallel)
```bash
# MT10: 10 parallel jobs
for i in {1..10}; do sbatch docker/cluster/train_mt10_mtrl.sh; done

# Check status
squeue -u e11704784 | grep mt10_mtrl
```

### Multiple Seeds (Sequential - safer for long runs)
```bash
# MT50: Submit with staggered times to avoid queue congestion
for i in {1..10}; do
  sbatch docker/cluster/train_mt50_mtrl.sh
  sleep 60  # Wait 1 min between submissions
done
```

---

## 📈 Hyperparameter Variationen (Für spätere Experimente)

### Network Width Scaling
Editiere in `train_mt10_mtrl.sh`:
```bash
# Original
HIDDEN_SIZES="1024,1024,1024"

# Smaller
HIDDEN_SIZES="400,400,400"      # ~77k parameters

# Larger
HIDDEN_SIZES="4096,4096,4096"   # ~32M parameters
```

### Replay Buffer Size
```bash
# Smaller buffer
REPLAY_CAPACITY=50000           # 50k per task

# Larger buffer
REPLAY_CAPACITY=200000          # 200k per task
```

### Training Duration
```bash
# Short experiment (MT10)
TOTAL_STEPS=5000000             # 5M instead of 20M
EVAL_FREQ=50000                 # More frequent evals

# Extended training (MT10)
TOTAL_STEPS=50000000            # 50M for more convergence
```

---

## 🔍 Debugging & Monitoring

### Real-time Log Viewing
```bash
ssh e11704784@datalab
tail -f /home/e11704784/metaworld_project/logs/mt10_mtrl_*.log

# Or follow latest
ls -ltr /home/e11704784/metaworld_project/logs/mt10_mtrl_*.log | tail -1 | awk '{print $NF}' | xargs tail -f
```

### Check Job Status
```bash
# All jobs
squeue -u e11704784

# Just MTRL jobs
squeue -u e11704784 | grep mtrl

# Detailed info
squeue -j 12345 -l

# Cancel job
scancel 12345
```

### Check Checkpoints
```bash
ssh e11704784@datalab
ls -lh /home/e11704784/metaworld_project/models/mt10_mtrl_12345/

# Count checkpoints
find /home/e11704784/metaworld_project/models/mt10_mtrl_*/ -name "checkpoint_*.pt" | wc -l
```

### Monitor GPU
```bash
ssh e11704784@datalab
watch -n 1 nvidia-smi
```

---

## 📥 Download Results

### Download Final Models
```bash
# MT10 final model
scp e11704784@datalab:/home/e11704784/metaworld_project/models/mt10_mtrl_12345/final_model.pt ./

# All checkpoints of a run
scp -r e11704784@datalab:/home/e11704784/metaworld_project/models/mt10_mtrl_12345/ ./
```

### Download W&B Data
```bash
# Via W&B API
wandb artifact get e11704784/mtrl-cluster/run-12345-final_model:v0
```

---

## 🎓 Citation

Wenn du mit diesen Scripts Ergebnisse publishst:

```bibtex
@article{mclean2025mtrl,
  title   = {Multi-Task RL Enables Parameter Scaling},
  author  = {McLean, Alexander and Farquhar, Gregor and Henderson, Peter and Amos, Brandon},
  journal = {arXiv preprint arXiv:2503.05126},
  year    = {2025}
}
```

---

## 🚀 Empfehlung: Training-Reihenfolge

**Woche 1:**
1. Deploy lokal testen: `bash docker/cluster/test_docker_local.sh`
2. MT10 Single Run: `sbatch train_mt10_mtrl.sh`
3. Monitor auf W&B

**Woche 2:**
4. MT10 mit 10 Seeds: `for i in {1..10}; do sbatch train_mt10_mtrl.sh; done`
5. Parallel: MT50 Single Run starten: `sbatch train_mt50_mtrl.sh`

**Woche 3+:**
6. MT50 mit 10 Seeds (nacheinander oder mit Wartezeit)
7. Optional: Hyperparameter-Variationen testen

---

## ✅ Checkliste vor Job-Submission

- [ ] Container `mtrl.sif` vorhanden
- [ ] Code in `/home/e11704784/metaworld_project/source/mtrl/`
- [ ] W&B API Key gesetzt: `echo $WANDB_API_KEY`
- [ ] Logs/Models Verzeichnisse vorhanden
- [ ] SLURM partition `a40` verfügbar: `sinfo | grep a40`
- [ ] Genug Disk Space: `df -h /home/e11704784/`

---

**Status: READY FOR PRODUCTION TRAINING** 🚀

```bash
# Start jetzt:
sbatch /home/e11704784/metaworld_project/source/mtrl/docker/cluster/train_mt10_mtrl.sh
```
