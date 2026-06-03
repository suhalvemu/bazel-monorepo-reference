# EngFlow (Managed RBE)

[EngFlow](https://engflow.com) is a commercial managed RBE platform built by ex-Google engineers who worked on Blaze (the internal predecessor to Bazel). Used by large engineering organizations that need enterprise SLAs.

## Configuration

```ini
# Add to user.bazelrc (credentials provided by EngFlow)
build:engflow --remote_cache=grpcs://<your-cluster>.engflow.com
build:engflow --remote_executor=grpcs://<your-cluster>.engflow.com
build:engflow --tls_client_certificate=engflow.crt
build:engflow --tls_client_key=engflow.key
build:engflow --jobs=100
```

Replace `<your-cluster>` with the hostname EngFlow assigns to your account.

## Authentication

EngFlow uses mTLS (mutual TLS) — both client and server present certificates. You receive `engflow.crt` and `engflow.key` from EngFlow upon account creation. Store them outside the repo and reference them by absolute path in `user.bazelrc`.

## vs BuildBuddy vs Buildbarn

| | EngFlow | BuildBuddy | Buildbarn |
|--|--|--|--|
| Type | Commercial managed | SaaS (free + paid) | Open-source self-hosted |
| Auth | mTLS | API key | Configurable |
| SLA | Enterprise (99.9%+) | Best-effort free tier | Self-managed |
| Built for | Very large monorepos | General Bazel teams | Self-hosted teams |
| Notable users | Large enterprises | Stripe, Sourcegraph | Pinterest, Spotify |

## When to Choose EngFlow

- You need guaranteed uptime SLAs for CI
- Your monorepo has 1000+ engineers building simultaneously
- You need dedicated isolated infrastructure (not multi-tenant)
- Compliance requirements prevent using shared SaaS

## Protocol

All RBE providers — EngFlow, BuildBuddy, Buildbarn — implement the same [Remote Execution API](https://github.com/bazelbuild/remote-apis) (gRPC + protobuf). The `.bazelrc` config is nearly identical across providers; switching is a one-line change.
