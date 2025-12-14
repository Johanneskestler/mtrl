# MTRL Cluster Training Pipeline

**Schnelle Zusammenfassung:** Docker bauen → testen → zu Singularity konvertieren → auf DataLAB hochladen → SAC-Training mit W&B starten.

---

## 🔧 Phase 1: Lokal Bauen & Testen (10-20 min)

### 1.1 Docker bauen
```bash
cd /path/to/mtrl
docker build -t mtrl:latest -f Dockerfile .
```

Oder mit Script:
```bash
bash docker/cluster/build_docker.sh
```

### 1.2 Lokal testen
```bash
bash docker/cluster/test_docker_local.sh
```

Was wird getestet:
- ✅ CUDA verfügbar
- ✅ PyTorch, JAX, MuJoCo installiert
- ✅ Meta-World MT10 Environment lädt
- ✅ W&B Logger funktioniert

**Ausgabe:** Sollte `✅ All tests passed!` zeigen.

---

## 📦 Phase 2: Singularity Konvertierung (15-30 min)

### 2.1 Zu Singularity konvertieren
```bash
singularity build mtrl.sif docker-daemon://mtrl:latest
```

Oder mit Script:
```bash
bash docker/cluster/convert_to_singularity.sh
```

**Ergebnis:** `mtrl.sif` Datei (~15GB) im Projekt-Root.

### 2.2 Singularity lokal testen
```bash
singularity exec --nv mtrl.sif python -c "import torch; print(torch.cuda.is_available())"
```

---

## 🚀 Phase 3: Upload zu DataLAB (15-30 min)

### 3.1 Vollständiger Deployment (empfohlen)
```bash
bash deploy_to_cluster.sh e11704784
```

Was macht das Script:
1. Docker lokal bauen (falls nicht bereits getan)
2. Zu Singularity konvertieren
3. Code zu Cluster hochladen (`/home/e11704784/metaworld_project/source/mtrl`)
4. Container hochladen (`/home/e11704784/metaworld_project/mtrl.sif`)
5. SBATCH Script bereitstellen

**Dauer:** Hängt von Internet-Speed ab, typisch 15-30 min für ~7GB Code+Container.

### 3.2 Nur Code hochladen (schneller)
Wenn Container bereits auf Cluster vorhanden:
```bash
bash docker/cluster/upload_code_to_cluster.sh e11704784
```

---

## 🏃 Phase 4: Cluster W&B Setup

### 4.1 SSH zum Cluster
```bash
ssh e11704784@datalab
cd /home/e11704784/metaworld_project
```

### 4.2 W&B API Key einrichten

Option A: Online Mode (empfohlen)
```bash
export WANDB_API_KEY='dein-api-key-von-wandb.ai'
# API Key holen: https://wandb.ai/authorize
```

Option B: Offline Mode (automatisch, falls kein Internet)
```bash
# Keine Aktion nötig - W&B speichert lokal
```

### 4.3 Verifizieren
```bash
singularity exec --nv mtrl.sif wandb login
# Oder einfach: export WANDB_API_KEY='...' und los geht's
```

---

## 🎓 Phase 5: Training Starten

### 5.1 Training Job einreichen
```bash
# Am Cluster
cd /home/e11704784/metaworld_project/source/mtrl

sbatch docker/cluster/train_mt10_sac_simple.sh
```

### 5.2 Job Status prüfen
```bash
# Alle deine Jobs
squeue -u e11704784

# Spezifisch MTRL
squeue -u e11704784 | grep mt10

# Live Log anschauen
tail -f /home/e11704784/metaworld_project/logs/mt10_sac_simple_*.log
```

### 5.3 W&B Ergebnisse
Öffne im Browser:
```
https://wandb.ai/e11704784/mtrl-cluster
```

---

## 📊 Training-Konfiguration

**SAC Simple Architecture** (aus `train_mt10_sac_simple.sh`):
- Algorithm: SAC (Standard, keine Multi-Task Extensions)
- Netzwerk: 2 FC layers à 256 Neuronen (KEINE Multi-Head, KEINE Soft Modules)
- Tasks: MT10 (10 Metaworld tasks)
- Steps: 2,000,000
- Batch: 256
- Eval frequency: 50,000 steps
- Checkpoints: Alle 100,000 steps

**Geschätzte Zeit:** 8-12 Stunden auf A40 GPU

---

## 🗂️ Dateistruktur auf DataLAB

```
/home/e11704784/metaworld_project/
├── logs/                          # SBATCH stdout/stderr
│   ├── mt10_sac_simple_12345.log
│   └── mt10_sac_simple_12345.err
├── models/                        # Checkpoints
│   └── mt10_sac_simple_12345/
│       ├── checkpoint_100000.pt
│       ├── checkpoint_200000.pt
│       └── final_model.pt
├── wandb_cache/                   # W&B offline cache
├── source/mtrl/                   # Dein Code
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── docker/cluster/
│   │   ├── train_mt10_sac_simple.sh  ← Training Script
│   │   ├── build_docker.sh
│   │   ├── convert_to_singularity.sh
│   │   └── ...
│   └── mtrl/
│       ├── monitoring/wandb_logger.py
│       ├── experiment.py
│       └── ...
└── mtrl.sif                       # Container (15GB)
```

---

## ⚡ Quick Commands (am Cluster)

```bash
# SSH
ssh e11704784@datalab
cd /home/e11704784/metaworld_project

# Training starten
sbatch source/mtrl/docker/cluster/train_mt10_sac_simple.sh

# Status
squeue -u e11704784

# Logs anschauen
tail -f logs/mt10_sac_simple_*.log

# W&B anzeigen
# https://wandb.ai/e11704784/mtrl-cluster

# Container testen
singularity exec --nv mtrl.sif python -c "import torch; print(torch.cuda.is_available())"

# Job abbrechen
scancel <JOB_ID>
```

---

## 🐛 Troubleshooting

| Problem | Lösung |
|---------|--------|
| `ModuleNotFoundError: mtrl` | Stelle sicher `source/mtrl` im Container mounted ist |
| `CUDA out of memory` | Reduziere `batch_size` in Script oder nutze MT1 statt MT10 |
| `W&B offline` | Normal wenn kein Internet; Daten werden lokal gespeichert |
| `Permission denied` | `chmod +x docker/cluster/*.sh` |
| Container nicht gefunden | `apptainer build mtrl.sif docker://mtrl:latest` am Cluster |

---

## 📝 Nächste Schritte nach Erfolg

1. **Ergebnisse checken:** W&B Dashboard
2. **Modelle downloaden:** (Optional) `scp e11704784@datalab:/home/e11704784/metaworld_project/models/mt10_sac_simple_*/final_model.pt .`
3. **Andere Architekturen trainieren:** Modifiziere `train_mt10_sac_simple.sh` für:
   - Multi-Task Heads
   - Soft Modules
   - PaCo (Adapter Networks)
   - GradNorm / PCGrad
4. **MT50 Training:** Ändere `NUM_TASKS=50` und Trainer-Config

---

## 🎓 Citation

Wenn du Results mit diesem Setup publishst, zitiere:
```
@article{mclean2025mtrl,
  title   = {Multi-Task RL Enables Parameter Scaling},
  author  = {McLean, Alexander and Farquhar, Gregor and Henderson, Peter and Amos, Brandon},
  journal = {arXiv preprint arXiv:2503.05126},
  year    = {2025}
}
```

---

**Status:** ✅ Ready to deploy!

```bash
# Starte jetzt:
bash deploy_to_cluster.sh e11704784
```
