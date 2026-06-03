# Self-Hosted Remote Cache (bazel-remote)

[bazel-remote](https://github.com/buchgr/bazel-remote) is the standard open-source Bazel cache server. It implements the Bazel Remote Execution API (cache-only mode) and runs as a Docker container.

## Start the Cache Server

```bash
docker-compose up -d
```

This starts `buchgr/bazel-remote-cache` with:
- **Port 9090** — HTTP cache endpoint
- **Port 9092** — gRPC cache endpoint (preferred — lower overhead)
- **10 GiB** max size with LRU eviction
- Persistent volume `bazel-remote-data`

## Connect Bazel

Use the config defined in `bazelrc.snippet` (already in this repo's `.bazelrc`):

```bash
bazel build //apps/go-service --config=bazel-remote
```

First build: cache miss — actions run locally, outputs uploaded to the server.
Second build (after `bazel clean`): cache hit — outputs downloaded, nothing compiled.

## Verify Cache Hits

```bash
bazel clean
bazel build //apps/go-service --config=bazel-remote
# Look for: "remote cache hit" in build output

bazel clean
bazel build //apps/go-service --config=bazel-remote
# All actions should show: (cached) PASSED
```

## Multi-Developer Setup

All developers on the same network point at the same server:

```bash
# .bazelrc (committed)
build:team-cache --remote_cache=grpc://cache.internal:9092
build:team-cache --remote_upload_local_results=true
```

`--remote_upload_local_results=true` is critical — without it, local builds read from the cache but never populate it.

## Compared to BuildBuddy

| | bazel-remote | BuildBuddy Free |
|--|--|--|
| Hosting | Self-managed | Managed SaaS |
| Build UI | None | Full invocation UI |
| Auth | Optional mTLS | API key |
| Cost | Infrastructure only | Free tier available |
