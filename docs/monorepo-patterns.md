# Monorepo Patterns with Bazel

## Dependency Graph

In this repo:

```
//apps/cpp-lib:greeter_test
    └── //apps/cpp-lib:greeter
    └── //libs/common:version        ← shared lib
    └── @googletest//:gtest_main

//apps/c-lib:greet_test
    └── //apps/c-lib:greet
    └── //libs/common:version        ← same shared lib

//apps/java-app:greeter_test
    └── //apps/java-app:greeter-app
    └── //proto:greeter_java_proto    ← generated from proto
    └── @maven//:junit_junit
```

Visualize with:
```bash
bazel query 'deps(//apps/cpp-lib:greeter_test)' --output=graph | dot -Tsvg > deps.svg
```

## Shared Libraries

`//libs/common:version` is depended on by multiple apps. Visibility enforces the direction:

```python
# libs/common/BUILD.bazel
cc_library(
    name = "version",
    visibility = ["//apps:__subpackages__"],  # apps can use it, nothing else
)
```

Find all reverse dependencies (what would break if you change this):
```bash
bazel query 'rdeps(//..., //libs/common:version)'
```

## Starlark Macros

Macros reduce BUILD file boilerplate. They run at loading time (not analysis time):

```python
# In a BUILD file:
load("//bazel:defs.bzl", "cc_library_with_test")

cc_library_with_test(
    name = "greeter",
    srcs = ["greeter.cc"],
    hdrs = ["greeter.h"],
    test_srcs = ["greeter_test.cc"],
    test_deps = ["@googletest//:gtest_main"],
)
# Expands to: cc_library(:greeter) + cc_test(:greeter_test)
```

## Custom Rules

Custom rules give full control over what Bazel does. See `bazel/rules.bzl`:

```python
generate_header(
    name = "project_header",
    out = "project.h",
    project_name = "bazel-cache-rbe-examples",
    version = "1.0.0",
)
```

Key rule concepts:
- `ctx.actions.write` — create a file with static content
- `ctx.actions.run` — run an executable
- `ctx.actions.run_shell` — run a shell command
- `DefaultInfo(files = depset([...]))` — declare what files this target produces

## Gazelle: Auto-generating BUILD files

For Go repos, Gazelle eliminates manual BUILD file maintenance:

```bash
bazel run //:gazelle          # update BUILD files based on Go imports
bazel run //:gazelle -- -mode=diff   # preview without applying
```

Gazelle reads your Go source files, finds `import` statements, and generates correct `deps` attributes. It only touches Go rules — `cc_library`, `py_library` etc. are untouched.

## Cross-language Proto

One `.proto` file generates code for all languages:

```
proto/greeter.proto
    → //proto:greeter_proto          (language-agnostic)
    → //proto:greeter_cc_proto       (C++)
    → //proto:greeter_java_proto     (Java)
    → //proto:greeter_go_proto       (Go)
```

This is the canonical Bazel monorepo pattern for service contracts.

## Platform-aware Builds

Cross-compile Go for Linux from macOS:
```bash
bazel build //apps/go-service --platforms=//platforms:linux_amd64
```

`rules_go` automatically sets `GOOS=linux GOARCH=amd64` based on the platform's constraint values. The binary is a Linux ELF — no separate Makefile or shell scripts needed.

## Build Stamping

Embed git commit into binaries at build time:
```bash
bazel build //apps/go-service --config=stamp
```

The binary now prints its git commit on startup. Stable values (STABLE_*) bust the cache when they change. Volatile values (BUILD_TIMESTAMP) do not — this prevents every PR from invalidating the entire build cache just because the timestamp changed.
