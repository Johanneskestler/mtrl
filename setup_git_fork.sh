#!/bin/bash
# Git Setup Script for MTRL Cluster Deployment
# Configures fork + team repo workflow

set -e

echo "=========================================="
echo "Git Setup for MTRL Cluster Deployment"
echo "=========================================="
echo ""

# Configuration
YOUR_GITHUB_USERNAME="${1:-}"
TEAM_REPO_URL="https://github.com/eisa22/rl_project_sac.git"
ORIGINAL_REPO_URL="https://github.com/rainx0r/mtrl.git"

# Validate input
if [ -z "$YOUR_GITHUB_USERNAME" ]; then
    echo "Usage: bash setup_git_fork.sh YOUR_GITHUB_USERNAME"
    echo "Example: bash setup_git_fork.sh john-doe"
    exit 1
fi

YOUR_FORK_URL="https://github.com/${YOUR_GITHUB_USERNAME}/mtrl.git"

echo "Configuration:"
echo "  GitHub Username: $YOUR_GITHUB_USERNAME"
echo "  Your Fork: $YOUR_FORK_URL"
echo "  Team Repo: $TEAM_REPO_URL"
echo "  Original: $ORIGINAL_REPO_URL"
echo ""

# Check if we're in the mtrl directory
if [ ! -f "pyproject.toml" ] && [ ! -f "requirements.txt" ]; then
    echo "❌ Error: Not in mtrl directory!"
    echo "   Run this from: /path/to/mtrl"
    exit 1
fi

echo "✓ Detected mtrl repository"
echo ""

# 1. Update origin to your fork
echo "1. Updating origin to your fork..."
git remote set-url origin "$YOUR_FORK_URL"
echo "   ✓ origin → $YOUR_FORK_URL"

# 2. Add upstream (original repo)
echo ""
echo "2. Adding upstream (original repo)..."
if git remote | grep -q "^upstream$"; then
    git remote set-url upstream "$ORIGINAL_REPO_URL"
    echo "   ✓ Updated upstream"
else
    git remote add upstream "$ORIGINAL_REPO_URL"
    echo "   ✓ Added upstream"
fi

# 3. Add team remote
echo ""
echo "3. Adding team repo remote..."
if git remote | grep -q "^team$"; then
    git remote set-url team "$TEAM_REPO_URL"
    echo "   ✓ Updated team"
else
    git remote add team "$TEAM_REPO_URL"
    echo "   ✓ Added team"
fi

# 4. Verify all remotes
echo ""
echo "4. Verifying remotes..."
echo ""
git remote -v
echo ""

# 5. Create feature branch
echo "5. Creating feature branch..."
if git branch | grep -q "feature/cluster-deployment"; then
    echo "   ⚠ Branch already exists, switching to it"
    git checkout feature/cluster-deployment
else
    git checkout -b feature/cluster-deployment
    echo "   ✓ Created feature/cluster-deployment"
fi

echo ""
echo "=========================================="
echo "✅ Git Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Review your changes:"
echo "   git status"
echo "   git diff origin/master"
echo ""
echo "2. Commit with message:"
echo "   git add ."
echo "   git commit -m 'feat: Add cluster deployment infrastructure'"
echo ""
echo "3. Push to your fork:"
echo "   git push -u origin feature/cluster-deployment"
echo ""
echo "4. Merge to team branch:"
echo "   git fetch team"
echo "   git checkout -b dev-johannes-mtrl-cluster"
echo "   git merge feature/cluster-deployment"
echo "   git push -u team dev-johannes-mtrl-cluster"
echo ""
echo "5. Create Pull Request on GitHub (optional but recommended):"
echo "   https://github.com/${YOUR_GITHUB_USERNAME}/mtrl/compare/feature/cluster-deployment"
echo ""
