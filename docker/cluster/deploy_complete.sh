#!/bin/bash
# Complete deployment workflow for MTRL to DataLAB cluster
# This script orchestrates container build, upload, and code sync

set -e

echo "=========================================="
echo "🚀 MTRL Complete Cluster Deployment"
echo "=========================================="
echo ""
echo "This will:"
echo "  1. ✅ Use existing SIF: /tmp/mtrl.sif (6.6G)"
echo "  2. 📤 Upload container to cluster (~30 min)"
echo "  3. 📁 Upload code to cluster (~1 min)"
echo "  4. ✅ Setup directories"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Step 1: Upload container
echo ""
echo "=========================================="
echo "📤 Step 1: Uploading Container"
echo "=========================================="
./deploy_new_container.sh

# Step 2: Upload code
echo ""
echo "=========================================="
echo "📁 Step 2: Uploading Code"
echo "=========================================="
./upload_code_to_cluster.sh

echo ""
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo ""
echo "Next Steps:"
echo "  1. SSH to cluster:"
echo "     ssh e11704784@datalab"
echo ""
echo "  2. Navigate to scripts:"
echo "     cd ~/metaworld_project/source/docker/cluster/course_project"
echo ""
echo "  3. Submit all jobs:"
echo "     ./submit_all.sh 42"
echo ""
echo "  4. Monitor jobs:"
echo "     squeue -u e11704784"
echo "     tail -f ~/metaworld_project/logs/*.log"
echo ""
echo "  5. View results:"
echo "     https://wandb.ai/Robot_learning_2025/Robot_learning_2025"
echo ""
echo "Expected Runtime:"
echo "  - MT1 REACH:      ~45 min (730 SPS)"
echo "  - MT1 PUSH:       ~45 min (730 SPS)"
echo "  - MT1 PICK-PLACE: ~45 min (730 SPS)"
echo "  - MT3:            ~19 min (1786 SPS)"
echo "  - Total (parallel): ~2.5 hours"
echo ""
echo "=========================================="
