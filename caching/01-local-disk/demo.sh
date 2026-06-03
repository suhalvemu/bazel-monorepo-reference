#!/bin/bash
# Demonstrates local disk cache hit/miss timing.
# Run from the workspace root.
set -e

CACHE_DIR=~/.cache/bazel-disk-cache
TARGET=//apps/go-service:go-service

echo "=== Cold build (no cache) ==="
bazel clean --expunge
rm -rf "${CACHE_DIR}"
time bazel build "${TARGET}" --disk_cache="${CACHE_DIR}"

echo ""
echo "=== Warm build (cache hit) ==="
bazel clean   # clears in-memory + local output, but NOT the disk cache
time bazel build "${TARGET}" --disk_cache="${CACHE_DIR}"
# Expected: near-instant — all actions served from disk cache
