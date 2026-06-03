# Determinism Checker — Problem Analysis and Design

## Problem Statement

A developer merges a PR. CI stays green. Tests pass. But over the next few days the team notices:
- Cache hit rate dropped from 90% to 30%
- Every build recompiles targets that haven't changed
- CI build time doubled

Nobody knows which PR caused it. The git history has 50 commits. The build logs say nothing useful.

**Root cause: someone introduced a non-deterministic build action — an action whose output changes between runs even when all inputs are identical.**

Bazel has no built-in way to catch this at PR time. By the time you notice the hit rate drop, the damage is already merged.

---

## Why This Is Hard to Catch Manually

### 1. It's invisible in test results

Non-determinism doesn't cause build failures. Tests still pass. The binary still runs. The only symptom is cache misses — which show up as slowness, not errors.

### 2. It's delayed

The impact isn't visible until the second or third build after the PR merges. By then the PR is forgotten.

### 3. It's hard to attribute

A cache miss on `//apps/cpp-lib:greeter` doesn't tell you which PR introduced the non-determinism. It could be in:
- The target itself
- Any of its transitive dependencies
- A toolchain change
- An environment variable that changed

### 4. It compounds silently

One non-deterministic genrule can cascade across hundreds of dependents. Every target that transitively depends on it will miss on every run.

```
tools:gen_version  ← non-deterministic (embeds timestamp)
    ↓
libs/common:version  ← cache miss (dep changed)
    ↓
apps/cpp-lib:greeter  ← cache miss
apps/c-lib:greet      ← cache miss
services/auth:server  ← cache miss
services/api:gateway  ← cache miss
... 200 more targets
```

---

## Root Causes of Non-Determinism in Bazel

### Category 1 — Timestamp Injection

The most common. A genrule or custom rule embeds the current time into its output.

```python
# BUILD file
genrule(
    name = "build_info",
    outs = ["build_info.h"],
    cmd = "echo '#define BUILD_TIME \"$(date)\"' > $@",  # ← different every second
)
```

```go
// Source code
var buildTime = time.Now().Format(time.RFC3339)  // ← set at compile time via ldflags
```

**Why it's hard to spot:** developers add timestamps with good intentions (debugging, audit logs). They don't realise it breaks caching.

### Category 2 — Non-Hermetic Tool Execution

A genrule calls a tool from `PATH` instead of a declared Bazel target.

```python
genrule(
    name = "gen_proto",
    outs = ["greeter.pb.go"],
    cmd = "protoc --go_out=$@ $<",  # ← uses system protoc, version unknown
)
```

Different machines, different CI images, different `protoc` versions → different output bytes → cache miss on every cross-machine build.

**Why it's hard to spot:** it works locally. It works on CI. But local machine has `protoc` 3.21 and CI has `protoc` 3.20. Outputs differ. Cache never hits across machines.

### Category 3 — Environment Variable Leakage

An action reads an environment variable that isn't declared as an input.

```python
genrule(
    name = "gen_config",
    outs = ["config.json"],
    cmd = "echo '{\"env\": \"'$$DEPLOY_ENV'\"}' > $@",  # ← reads $DEPLOY_ENV
)
```

`DEPLOY_ENV=prod` on one machine, `DEPLOY_ENV=dev` on another → different outputs → cache miss.

Bazel's sandbox blocks most env vars, but `--action_env` can leak them in without being part of the declared action key.

### Category 4 — Non-Deterministic Source Generation

Custom Starlark rules that produce outputs with randomness, ordering issues, or system-dependent content.

```python
def _my_rule_impl(ctx):
    out = ctx.actions.declare_file("output.txt")
    ctx.actions.run_shell(
        outputs = [out],
        command = "ls /tmp > %s" % out.path,  # ← /tmp content varies
    )
```

```python
# Map/set iteration order in Python 2 (now rare but still seen in older rules)
for key in my_dict:  # ← order not guaranteed in Python 2
    write_to_output(key)
```

### Category 5 — Glob Instability

Not non-determinism in the strict sense, but a related problem. Over-broad globs include files that change frequently, causing unnecessary cache invalidation.

```python
# Everything in the repo is an input — any file change = cache miss
srcs = glob(["**/*"])

# Catches test outputs, editor swap files, etc.
srcs = glob(["src/**"], exclude_directories = 0)
```

This doesn't produce different bytes — it produces cache misses on every unrelated change, which has the same symptom (low hit rate) but a different cause.

### Category 6 — Stamping Without STABLE_ Prefix

Using workspace status variables incorrectly.

```bash
# workspace_status.sh
echo "GIT_COMMIT $(git rev-parse HEAD)"     # ← missing STABLE_ prefix
echo "BUILD_TIME $(date)"                   # ← volatile, should be fine without prefix
```

Without `STABLE_` prefix, `GIT_COMMIT` is treated as volatile — Bazel reads it but excludes it from the action key. So stamped binaries get cache hits even when the commit changes, which means the embedded commit is stale. This is the opposite problem — false cache hits rather than false misses. But it's still incorrect behaviour.

---

## Impact Quantification

From real-world data and the Kubernetes build study:

| Scenario | Cache hit rate without fix | Cache hit rate with fix |
|----------|--------------------------|------------------------|
| One timestamp genrule in shared lib | 20-40% | 90%+ |
| System tool in PATH (cross-machine) | 0% cross-machine | 85%+ |
| Env var leakage | 50-70% | 90%+ |
| Over-broad glob (busy repo) | 40-60% | 85%+ |

**Cost in CI compute (50-engineer team, 100 builds/day):**

```
Healthy cache (90% hit rate):
  100 builds × 10 actions × 10% miss = 100 local actions/day

Broken cache (20% hit rate):
  100 builds × 10 actions × 80% miss = 800 local actions/day

= 8x more compute cost from one non-deterministic action
```

At $0.10/action-minute on cloud CI, a single broken genrule can cost thousands per month at scale.

---

## Detection Approaches

### Approach 1 — Static Analysis

Scan changed BUILD files and source files for known bad patterns using regex or AST parsing.

**Pros:**
- Fast (seconds)
- No build required
- Catches obvious cases before they're merged
- Can suggest fixes inline

**Cons:**
- False positives — `$(date)` in a comment triggers it
- False negatives — complex custom rules with hidden non-determinism won't be caught
- Can't detect runtime non-determinism (random seeds, map iteration)

**Detectable patterns:**
```
BUILD files:
  genrule cmd containing: date, hostname, whoami, curl, wget, $RANDOM, $PID, $PPID
  genrule cmd reading from /tmp, /var, /home without sandbox
  glob(["**/*"]) or glob(["**"]) — too broad
  Tool references using PATH instead of $(location)

Source files:
  time.Now() / time.Since() assigned to package-level var (Go)
  datetime.now() in module-level code (Python)
  System.currentTimeMillis() in static initialiser (Java)
  __DATE__ / __TIME__ macros (C/C++)
  std::time / std::chrono at static init time (C++)
```

### Approach 2 — Dynamic Analysis (Build Twice, Compare Hashes)

Build the affected targets twice from a cold state using an isolated disk cache. Compare output hashes.

```
PR opened
  → find affected targets (bazel query rdeps of changed files)
  → mkdir /tmp/det-cache-run1 /tmp/det-cache-run2
  → bazel clean && bazel build //affected/... --disk_cache=/tmp/det-cache-run1
  → bazel clean && bazel build //affected/... --disk_cache=/tmp/det-cache-run2
  → compare cache entry hashes between run1 and run2
  → any difference = non-deterministic action found
```

**Why compare disk cache entries rather than output files?**
Disk cache entries are keyed by action input hash. If the same action key produces different output content in two runs, the cache will have two different entries for the same key — detectable as a collision.

**Pros:**
- Definitive — no false positives
- Catches non-determinism that static analysis misses (runtime randomness, complex rules)
- Uses Bazel's own machinery — no custom tooling needed beyond the comparison

**Cons:**
- Slow — 2x build time for affected targets
- Expensive on large repos with many affected targets
- Can't tell you WHY an action is non-deterministic, only THAT it is
- Flaky: network calls, external API hits in genrules may pass or fail depending on environment

### Approach 3 — Execution Log Diff

Run with `--execution_log_compact_file` on two separate runs and diff the logs.

```bash
bazel build //... --execution_log_compact_file=/tmp/run1.log
bazel clean
bazel build //... --execution_log_compact_file=/tmp/run2.log
bazel-execlog diff /tmp/run1.log /tmp/run2.log
```

The diff shows exactly which input changed between runs — the specific file, its old hash, and its new hash.

**Pros:**
- Pinpoints the exact input that changed
- Doesn't require comparing raw output files
- Official Bazel tooling

**Cons:**
- Requires `bazel-execlog` tool installed
- Logs can be very large on big repos
- Same 2x build time cost

---

## Recommended Approach: Two-Layer Detection

### Layer 1 — Static (PR opens, fast feedback)

Run in < 30 seconds on every PR. Scans changed BUILD files and source files.
Reports: "This change has patterns that commonly cause non-determinism."
Does NOT block the PR — warns only.

### Layer 2 — Dynamic (PR targets for merge, definitive check)

Run only when PR is labelled `ready-for-merge` or on a scheduled nightly run.
Builds affected targets twice, compares disk cache entries.
Reports: "These specific actions produced different outputs between runs."
CAN block merge if configured to do so.

---

## What a PR Comment Should Contain

```
## 🔍 Determinism Check

### Static Analysis — ⚠️ 1 warning found

| File | Line | Pattern | Risk | Suggestion |
|------|------|---------|------|------------|
| tools/BUILD.bazel | 15 | `$(date)` in genrule cmd | HIGH | Use --stamp with STABLE_ prefix instead |

### Dynamic Analysis — ✅ All 14 actions deterministic

Built //apps/cpp-lib:greeter and 13 dependent targets twice.
All output hashes matched between run 1 and run 2.
Cache hit rate on run 2: 100%

---
ℹ️ Static analysis checks for known patterns. Dynamic analysis is the ground truth.
A static warning without a dynamic failure means the pattern exists but may not cause issues in practice.
```

---

## Edge Cases and Limitations

### 1. Deterministic on same machine, non-deterministic cross-machine

Two runs on the same CI agent may produce identical hashes even for non-hermetic builds (same PATH, same tool versions). The problem only appears when comparing builds from two different machines.

**Mitigation:** run the two builds in different Docker containers with intentionally different environments.

### 2. Intentional non-determinism

Some targets are intentionally non-deterministic — randomised tests, fuzzing targets, security key generation.

**Mitigation:** allow targets to opt out via a tag:
```python
cc_test(
    name = "fuzz_test",
    tags = ["non-deterministic"],  # skip determinism check
)
```

### 3. Flaky genrules that call external services

A genrule that calls an external API will sometimes pass and sometimes fail, making the dynamic check flaky.

**Mitigation:** static analysis should flag external network calls (`curl`, `wget`, `http`) as HIGH risk and fail fast without running the dynamic check.

### 4. Large monorepo — too many affected targets

On a 10,000-target monorepo, a change to a shared library could affect thousands of targets. Building all of them twice is infeasible on a PR.

**Mitigation:** cap the dynamic check at the directly changed targets + 1 level of dependents. Full graph check runs nightly, not per-PR.

---

## Files to Create

```
.github/workflows/determinism-check.yml   ← CI workflow (triggers on PR)
tools/check_determinism.sh                ← static + dynamic analysis runner
tools/static_analysis_patterns.txt        ← list of bad patterns with risk levels
docs/determinism-checker-design.md        ← this document
```

---

## Open Questions Before Implementation

1. **Block or warn?** Should a HIGH static finding block the PR, or only warn? Recommendation: warn on static, block on dynamic failure.

2. **Which targets to check dynamically?** All affected targets, or only targets that static analysis flagged? Recommendation: static-flagged targets always get dynamic check; others only if the affected set is small (< 20 targets).

3. **Where to run?** Same CI agent (misses cross-machine issues) or two separate agents? Recommendation: same agent for now — catches the majority of cases. Cross-agent check is a future improvement.

4. **What to do with external tool calls in genrules?** Flag as HIGH risk and recommend migrating to a declared Bazel target. Don't attempt to sandbox-test them.
