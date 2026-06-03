#!/bin/bash
# Creates a GCS bucket for Bazel remote cache with a 30-day lifecycle policy.
set -e

PROJECT_ID=${1:?Usage: setup.sh <gcp-project-id>}
BUCKET="bazel-cache-${PROJECT_ID}"

echo "Creating bucket gs://${BUCKET}..."
gsutil mb -p "${PROJECT_ID}" "gs://${BUCKET}"

# Apply a lifecycle rule to expire objects older than 30 days.
# Without this, the cache grows unbounded and incurs ongoing storage cost.
cat > /tmp/lifecycle.json << 'EOF'
{
  "rule": [{
    "action": {"type": "Delete"},
    "condition": {"age": 30}
  }]
}
EOF
gsutil lifecycle set /tmp/lifecycle.json "gs://${BUCKET}"

echo ""
echo "Done. Add to your user.bazelrc:"
echo "  build --config=gcs"
echo "  export GCS_BUCKET=${BUCKET}"
