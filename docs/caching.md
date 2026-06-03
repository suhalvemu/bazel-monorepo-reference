# Bazel Caching

## How Bazel Caching Works

Every action (compile, link, test) has a **cache key** derived from:
- All input file contents (hashed)
- The command being run
- Environment variables declared in the action
- Bazel version and toolchain configuration

If the cache key matches a stored result, the action is skipped and outputs are downloaded. This is content-addressed caching — not time-based or path-based.

## Cache Layers

```
L1: In-memory (analysis cache)   ← lost on bazel server restart
L2: Local disk cache              ← persists across clean, survives restart
L3: Remote cache                  ← shared across all machines/CI
```

## Caching Options in this Repo

| Config | Command | Best For |
|--------|---------|---------|
| Local disk | `--config=local-cache` | Single developer, offline |
| bazel-remote | `--config=bazel-remote` | Self-hosted team cache |
| BuildBuddy | `--config=buildbuddy-cache` | Free hosted cache + UI |
| GCS | `--config=gcs` | GCP teams, large artifacts |

## Real-World Cost Savings

| Scenario | Before | After | Savings |
|----------|--------|-------|---------|
| Sourcegraph (Aspect Workflows) | Baseline CI | 2-3x faster | 40% compute cost reduction |
| Kubernetes study (Bazel vs Go build) | — | 23-38% faster full builds | 22-39% lower CI cost |
| Incremental builds | full rebuild | cache hit | up to 75% faster |

## Cache Hit Rate

A well-tuned setup achieves 80-95% cache hit rate in CI. Key factors:
- **Remote upload enabled**: `--remote_upload_local_results=true` — without this, local builds don't populate the shared cache
- **Hermetic toolchains**: Non-hermetic builds have environment-dependent outputs that don't cache across machines
- **Stable inputs**: Avoid `genrule` outputs that embed timestamps (volatile by nature)

## Cache Invalidation

Cache is invalidated per-action when any input changes:

```
change greeter.cc
  → greeter.cc hash changes
  → cc_library(:greeter) cache key changes → rebuild
  → cc_test(:greeter_test) cache key changes → retest
  → everything else: cache hit
```

No full rebuild. Only the dirty subgraph rebuilds.
