#!/bin/bash
# Workspace status command for Bazel stamping.
# Run via: bazel build --stamp --workspace_status_command=stamp/workspace_status.sh
#
# Outputs two kinds of variables:
#   STABLE_*   — changes to these values invalidate the build cache for stamped targets.
#   (no prefix) — volatile; changes do NOT invalidate the cache (e.g. timestamps).
#
# Only go_binary targets with x_defs, and targets that explicitly request stamping,
# will embed these values. Most targets are unaffected.

echo "STABLE_GIT_COMMIT $(git rev-parse HEAD 2>/dev/null || echo 'unknown')"
echo "STABLE_GIT_BRANCH $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
echo "BUILD_TIMESTAMP $(date -u +%Y-%m-%dT%H:%M:%SZ)"
