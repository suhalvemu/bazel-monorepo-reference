# Remote Build Execution (RBE)

## RBE vs Remote Cache: The Key Distinction

| | Remote Cache | RBE |
|--|--|--|
| **What it stores** | Build action outputs | — |
| **Where actions run** | Local machine | Remote worker farm |
| **Parallelism** | Limited to local CPUs | Unlimited remote workers |
| **Cache** | Yes (implicit) | Yes (as a side effect) |
| **Network** | Download outputs | Upload inputs + download outputs |
| **Best for** | Any team size | Large repos, many targets |

**Cache stores outputs. RBE executes actions remotely.**

With remote cache alone: you still compile locally, but skip already-cached actions.
With RBE: you upload source + toolchain references, a remote worker compiles, you download the result.

## Why RBE is Transformative at Scale

A monorepo with 1000 engineers building at the same time:
- **Without RBE**: each engineer's machine runs N parallel local jobs. Max parallelism = cores on one machine.
- **With RBE**: Bazel distributes across a worker farm. 500 compile actions run simultaneously across 500 workers.

The Kubernetes study showed RBE speedup scales near-linearly with workers:

| Workers | Speedup vs sequential |
|---------|-----------------------|
| 2 | 2.0x |
| 4 | 3.84x |
| 8 | 7.36x |
| 16 | 12.8x |

## RBE Options in this Repo

| Config | Type | Setup |
|--------|------|-------|
| `--config=buildbuddy-rbe` | Managed (free tier) | Sign up at app.buildbuddy.io |
| `--config=buildbarn` | Self-hosted | `docker-compose up` in `rbe/02-buildbarn/` |
| `--config=engflow` | Managed (commercial) | Enterprise contract |

## Platform Constraints

Remote workers need to know what OS/arch to use. Set via:
```
build --remote_default_exec_properties=OSFamily=linux
```

Or per-target:
```python
go_binary(
    name = "server",
    exec_properties = {"OSFamily": "linux"},
    ...
)
```

## Protocol

Bazel uses the [Remote Execution API](https://github.com/bazelbuild/remote-apis) (gRPC + protobuf). All RBE providers (BuildBuddy, Buildbarn, EngFlow) implement this open standard — configs are interchangeable.

## When NOT to Use RBE

- Small repos (< 5 engineers): cache alone is sufficient
- Highly local builds (macOS-only toolchains): remote Linux workers can't run macOS toolchains
- Sensitive source code without a trusted RBE provider
