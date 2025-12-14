# 🚀 Git Workflow Cheatsheet - MTRL Cluster + Team Repo

**Situation:** Du hast lokale Änderungen, willst Fork + Team-Repo Setup

---

## 📋 SCHRITT-FÜR-SCHRITT ANLEITUNG

### Phase 1: Fork auf GitHub (2 min, im Browser)

```
https://github.com/rainx0r/mtrl
    ↓ Klick "Fork" oben rechts
https://github.com/YOUR-USERNAME/mtrl
```

---

### Phase 2: Lokales Git Setup (5 min)

**Automatisch (empfohlen):**
```bash
cd /path/to/mtrl
bash setup_git_fork.sh YOUR-USERNAME
# Ersetze YOUR-USERNAME mit deinem GitHub-Namen!
# z.B.: bash setup_git_fork.sh johannesmuster
```

**Manuell (wenn Script nicht funktioniert):**
```bash
# Überprüfe aktuelle Remotes
git remote -v

# Ändere origin zu deinem Fork
git remote set-url origin https://github.com/YOUR-USERNAME/mtrl.git

# Füge Original als upstream hinzu
git remote add upstream https://github.com/rainx0r/mtrl.git

# Füge Team-Repo hinzu
git remote add team https://github.com/eisa22/rl_project_sac.git

# Verifiziere
git remote -v
# Sollte zeigen:
#   origin    https://github.com/YOUR-USERNAME/mtrl.git (fetch/push)
#   upstream  https://github.com/rainx0r/mtrl.git (fetch/push)
#   team      https://github.com/eisa22/rl_project_sac.git (fetch/push)
```

---

### Phase 3: Feature Branch + Commit (10 min)

```bash
# Falls noch nicht auf feature branch:
git checkout -b feature/cluster-deployment

# Prüfe was geändert hat
git status

# Automatischer Commit (mit meiner Message):
bash commit_changes.sh
# Beantworte "Continue? (y/n)" mit "y"

# ODER manuell committen:
git add .
git commit -m "feat: Add Singularity & SLURM cluster deployment

- Add Dockerfile, requirements.txt, .dockerignore
- Add docker/cluster scripts (build, convert, upload)
- Add SLURM job scripts (test, full training)
- Add W&B logging integration
- Add comprehensive documentation

Based on original rainx0r/mtrl (https://github.com/rainx0r/mtrl)
Paper: McLean et al. (2025) - Multi-Task RL Enables Parameter Scaling
https://arxiv.org/abs/2503.05126"
```

---

### Phase 4: Push zu DEINEM Fork (2 min)

```bash
# Push feature branch zu deinem Fork
git push -u origin feature/cluster-deployment

# Verifiziere auf GitHub
# https://github.com/YOUR-USERNAME/mtrl/tree/feature/cluster-deployment
```

---

### Phase 5: Merge zum Team-Repo (5 min) ⭐ WICHTIG

```bash
# Fetch team repo
git fetch team

# Erstelle/checkout team branch
git checkout -b dev-johannes-mtrl-cluster

# Merge deine cluster-changes rein
git merge feature/cluster-deployment

# Push zum Team-Repo
git push -u team dev-johannes-mtrl-cluster

# Verifiziere auf GitHub
# https://github.com/eisa22/rl_project_sac/tree/dev-johannes-mtrl-cluster
```

---

## 🎯 Visuelle Übersicht (Was passiert)

```
┌─────────────────────────────────────────────────────────┐
│ Original Repo (rainx0r/mtrl)                            │
│ ← Read-Only (upstream)                                  │
└────────────────────┬────────────────────────────────────┘
                     │
                     │ (Fork Button)
                     ↓
┌─────────────────────────────────────────────────────────┐
│ Dein Fork (YOUR-USERNAME/mtrl)                          │
│ ← feature/cluster-deployment (mit meinen Änderungen)    │
└────────────────────┬────────────────────────────────────┘
                     │
                     │ (git push-u origin ...)
                     │
                     ↓ (git merge origin/feature/cluster...)
┌─────────────────────────────────────────────────────────┐
│ Team Repo (eisa22/rl_project_sac)                       │
│ ← dev-johannes-mtrl-cluster                             │
│   ├─ Meine Cluster-Änderungen                           │
│   ├─ Team kann reviewen & collaborate                   │
│   └─ Later: Optional PR zur main                        │
└─────────────────────────────────────────────────────────┘
```

---

## 📊 Git Graph (nach allen Steps)

```
Lokal:
    feature/cluster-deployment  ← du bist hier
        │
        └─ origin/feature/cluster-deployment (auf deinem Fork)

    dev-johannes-mtrl-cluster   ← später
        │
        └─ team/dev-johannes-mtrl-cluster (auf Team-Repo)

Remotes:
    origin  → https://github.com/YOUR-USERNAME/mtrl.git
    upstream → https://github.com/rainx0r/mtrl.git
    team    → https://github.com/eisa22/rl_project_sac.git
```

---

## 🔄 Später: Sync mit Original (wenn Original Updates hat)

```bash
# Fetch updates vom Original
git fetch upstream

# Rebase deine Changes auf neueste Version
git rebase upstream/master feature/cluster-deployment

# Force-push zu deinem Fork (Achtung: nur wenn allein!)
git push origin feature/cluster-deployment --force-with-lease

# Merge zu team branch
git checkout dev-johannes-mtrl-cluster
git merge feature/cluster-deployment
git push team dev-johannes-mtrl-cluster
```

---

## ⚠️ Wichtig: Citation & Attribution

**In jedem Commit erwähnen:**
```
Based on original rainx0r/mtrl
Paper: McLean et al. (2025)
https://github.com/rainx0r/mtrl
https://arxiv.org/abs/2503.05126
```

**In README (den du später schreibst):**
```markdown
## Original Work

This project adapts the MTRL work from:
- Repository: https://github.com/rainx0r/mtrl
- Paper: [cite paper]

See [CITATIONS.md](./CITATIONS.md) for full attribution.
```

---

## 🆘 Falls etwas schiefgeht

| Problem | Lösung |
|---------|--------|
| "fatal: destination path already exists" | `git checkout dev-johannes-mtrl-cluster` (branch existiert schon) |
| "nothing to commit" | `git add .` & `git status` prüfen |
| "Permission denied" | SSH-Key nicht konfiguriert: `ssh-keygen -t ed25519` |
| "remote origin already exists" | `git remote remove origin` dann neu hinzufügen |
| "Your branch has diverged" | `git pull --rebase` or `git reset --hard origin/branch` |

---

## ✅ Checklist zum Abhaken

- [ ] Fork auf GitHub erstellt
- [ ] `setup_git_fork.sh YOUR-USERNAME` ausgeführt
- [ ] `git remote -v` zeigt 3 remotes (origin, upstream, team)
- [ ] `git checkout feature/cluster-deployment` funktioniert
- [ ] `git status` zeigt meine neuen Dateien
- [ ] `bash commit_changes.sh` erfolgreich
- [ ] `git push -u origin feature/cluster-deployment` erfolgreich
- [ ] Auf GitHub sichtbar: https://github.com/YOUR-USERNAME/mtrl/tree/feature/cluster-deployment
- [ ] `git fetch team` erfolgreich
- [ ] `git checkout -b dev-johannes-mtrl-cluster` erstellt branch
- [ ] `git merge feature/cluster-deployment` erfolgreich
- [ ] `git push -u team dev-johannes-mtrl-cluster` erfolgreich
- [ ] Auf Team-GitHub sichtbar: https://github.com/eisa22/rl_project_sac/tree/dev-johannes-mtrl-cluster

---

## 🎓 Erklärung: Warum diese Struktur?

```
Feature Branch (dein Fork) → für deine Cluster-Anpassungen
    ↓
Team Branch (Team-Repo)    → für Team Collaboration & Tracking

Vorteil:
✅ Dein Fork: Saubere Baseline für PRs zum Original (falls gewünscht)
✅ Team Branch: Zentraler Ort für euer Projekt
✅ Separation of Concerns: Klar wer was macht
✅ Easy to Review: Team kann Änderungen reviewen
✅ Optional PR: Später PRs zum Original, wenn sauber genug
```

---

## 🚀 Nächste Schritte nach Git-Setup

1. ✅ Git Setup fertig
2. ▶️ Docker Build lokal: `bash docker/cluster/build_docker.sh`
3. ▶️ Singularity: `bash docker/cluster/convert_to_singularity.sh`
4. ▶️ Upload: `bash docker/cluster/upload_code_to_cluster.sh e11704784`
5. ▶️ W&B: SSH + `setup_wandb.sh`
6. ▶️ Training: `sbatch train_mt10_test.sh`
7. ▶️ Results: W&B Dashboard + Team Repo

---

**Bereit?** Führe das aus:

```bash
cd /path/to/mtrl
bash setup_git_fork.sh YOUR-GITHUB-USERNAME  # Replace with real username!
```

Dann schreib mir Bescheid wenn es funktioniert! 🚀
