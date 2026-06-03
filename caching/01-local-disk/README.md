# Local Disk Cache

Bazel's simplest caching layer — persists build outputs to a directory on the local machine.

## How It Works

Every build action (compile, link, test) produces outputs identified by a content hash of all inputs. With a disk cache, Bazel stores those outputs in `~/.cache/bazel-disk-cache`. On the next build, if all inputs are identical, Bazel reads the cached output instead of re-executing the action.

Unlike Bazel's in-memory analysis cache (which is lost on `bazel clean` or server restart), the disk cache survives both.

## Setup

```bash
# One-time: add to .bazelrc or use --config=local-cache
build:local-cache --disk_cache=~/.cache/bazel-disk-cache
```

Or use the config already defined in this repo's `.bazelrc`:

```bash
bazel build //apps/go-service --config=local-cache
```

## Demo

```bash
# Run the timing demo to see cold vs warm build
chmod +x demo.sh && ./demo.sh
```

Expected output:
```
=== Cold build (no cache) ===
real    0m22s

=== Warm build (cache hit) ===
real    0m2s     ← ~90% faster
```

## When to Use

| Scenario | Recommendation |
|----------|---------------|
| Solo developer, fast laptop | Good default — zero setup |
| Shared team cache needed | Upgrade to bazel-remote or BuildBuddy |
| CI agents (ephemeral) | Use remote cache instead — disk cache doesn't survive agent recycling |

## Key Facts

- Cache is **shared across all workspaces** on the machine — if you have two repos using the same dep, they share cache hits
- Safe to delete: `rm -rf ~/.cache/bazel-disk-cache` — Bazel rebuilds from scratch
- Size is unbounded by default; add `--disk_cache_max_size=10g` to cap it
