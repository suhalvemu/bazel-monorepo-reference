# BuildBuddy RBE (Remote Build Execution)

BuildBuddy's free tier includes RBE — build actions execute on remote workers instead of your local machine.

## Cache vs RBE: The Difference

| Remote Cache | RBE |
|---|---|
| Your machine compiles; results stored remotely | Remote workers compile; you download the result |
| Parallelism limited to your CPU cores | Parallelism unlimited (50+ concurrent actions) |
| Speeds up repeated builds (cache hits) | Speeds up first builds (parallel execution) |

Use both together for maximum benefit — this config (`buildbuddy-rbe`) inherits `buildbuddy-cache`.

## Setup

Same as caching setup — you need a BuildBuddy API key in `user.bazelrc`:
```ini
build --remote_header=x-buildbuddy-api-key=YOUR_KEY
```

## Run

```bash
bazel build //apps/go-service --config=buildbuddy-rbe
bazel test //apps/... --config=buildbuddy-rbe
```

## Config Explained

```ini
build:buildbuddy-rbe --config=buildbuddy-cache          # inherit remote cache
build:buildbuddy-rbe --remote_executor=grpcs://remote.buildbuddy.io
build:buildbuddy-rbe --jobs=50                          # up to 50 concurrent remote actions
build:buildbuddy-rbe --remote_default_exec_properties=OSFamily=linux
```

`--remote_default_exec_properties=OSFamily=linux` tells BuildBuddy to schedule actions on Linux workers. Required when building from macOS targeting a Linux toolchain.

## Platform Constraints

Remote workers need the right toolchain. `rules_go` hermetic toolchains work on Linux workers out of the box. C/C++ cross-compilation from macOS requires explicit platform configuration (see `platforms/`).

## Observing RBE in the UI

Open the BuildBuddy invocation URL printed during the build. The **Execution** tab shows:
- Which actions ran remotely vs locally
- Worker assignment and queue time
- Inputs uploaded, outputs downloaded
- Action cache hit/miss per target

## Scaling Effect

| Workers | Speedup vs sequential |
|---------|-----------------------|
| 2 | 2.0x |
| 4 | 3.84x |
| 8 | 7.36x |
| 16 | 12.8x |

Source: Kubernetes build system study (arxiv 2510.20041).
