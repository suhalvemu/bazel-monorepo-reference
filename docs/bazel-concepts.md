# Bazel Core Concepts

## The Three Phases of a Bazel Build

```
Loading → Analysis → Execution
```

| Phase | What happens | Files involved |
|-------|-------------|----------------|
| **Loading** | BUILD files evaluated, macros run, package graph built | `BUILD.bazel`, `.bzl` |
| **Analysis** | Rules evaluated, action graph built, no I/O | `rules.bzl`, `.bzl` |
| **Execution** | Actions run (compile, link, test), outputs cached | Source files, toolchains |

## Targets, Labels, and Packages

**Package** — a directory containing a `BUILD.bazel` file.

**Target** — a named buildable unit inside a package:
- `cc_library(name = "greeter")` → target `greeter`
- `go_binary(name = "go-service")` → target `go-service`

**Label** — fully qualified address of a target:
```
//apps/go-service:go-service
  │    │            └── target name
  │    └── package path (relative to workspace root)
  └── workspace root marker
```

Shorthand: `//apps/go-service` expands to `//apps/go-service:go-service` (target name = directory name).

## BUILD Files

```python
# Load rules from a ruleset
load("@rules_go//go:def.bzl", "go_binary", "go_test")

# Declare a target
go_binary(
    name = "go-service",
    srcs = ["main.go"],
    visibility = ["//visibility:public"],  # who can depend on this
)
```

## Dependency Graph

Bazel tracks the full dependency graph. When you change a file, only targets that (transitively) depend on it are rebuilt. This is what makes Bazel fast at scale.

```
//apps/cpp-lib:greeter_test
    └── //apps/cpp-lib:greeter
    └── @googletest//:gtest_main
            └── (hermetic toolchain)
```

## Hermeticity

Bazel actions are hermetic — they only see declared inputs. No environment variables, no network access, no undeclared files. This guarantees:
- The same inputs always produce the same outputs (reproducibility)
- Results can be safely cached and shared across machines

## Visibility

Controls who can depend on a target:

```python
visibility = ["//visibility:public"]         # anyone
visibility = ["//visibility:private"]        # same package only (default)
visibility = ["//apps:__subpackages__"]      # all packages under apps/
visibility = ["//apps/go-service:__pkg__"]  # only this package
```
