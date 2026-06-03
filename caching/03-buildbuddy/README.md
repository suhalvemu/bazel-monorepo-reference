# BuildBuddy Remote Cache (Free Tier)

[BuildBuddy](https://app.buildbuddy.io) is a managed Bazel cache and RBE platform. The free tier provides remote caching with a web UI showing build results, cache hit rates, and timing breakdowns.

## Setup (5 minutes)

1. Sign up at [app.buildbuddy.io](https://app.buildbuddy.io)
2. Go to **Settings → API Keys → Create**
3. Copy the key into `user.bazelrc` (gitignored):

```bash
echo "build --remote_header=x-buildbuddy-api-key=YOUR_KEY" >> user.bazelrc
```

4. Build:

```bash
bazel build //apps/go-service --config=buildbuddy-cache
```

BuildBuddy prints an invocation URL in the build output:
```
Build will be available at: https://app.buildbuddy.io/invocation/abc123
```

## What the UI Shows

- **Cache hit rate** — % of actions served from cache (target: 80-95%)
- **Build duration timeline** — which targets were on the critical path
- **Test results** — pass/fail per test, logs inline
- **Invocation history** — compare builds across time

## Config

```ini
# .bazelrc (committed — no secrets here)
build:buildbuddy-cache --remote_cache=grpcs://remote.buildbuddy.io
build:buildbuddy-cache --remote_upload_local_results=true

# user.bazelrc (gitignored — secret here)
build --remote_header=x-buildbuddy-api-key=YOUR_KEY
```

The `try-import %workspace%/user.bazelrc` line in `.bazelrc` loads the key file if it exists, silently skipping it in CI where the key is injected via environment/secrets.

## POC Results from This Repo

| Build | Time | Actions |
|-------|------|---------|
| Cold (first run) | 22s | 4 local compile |
| Warm (cache hit) | 4.7s | 4 remote cache hit, 0 local |

**79% faster** on the second run with zero local compilation.

## Upgrade to RBE

To go from caching to full remote execution (actions run on BuildBuddy workers):

```bash
bazel build //... --config=buildbuddy-rbe
```

See `rbe/01-buildbuddy-rbe/` for details.
