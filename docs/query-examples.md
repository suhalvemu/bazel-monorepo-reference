# Bazel Query Examples

Bazel has three query tools for different levels of the build graph:

| Tool | Graph level | Use when |
|------|------------|----------|
| `bazel query` | Target graph (load time) | Find targets, deps, rdeps |
| `bazel cquery` | Configured targets (analysis time) | Inspect `select()`, platforms |
| `bazel aquery` | Action graph (execution time) | See exact commands, inputs, outputs |

All examples below run from the workspace root of this repo.

---

## bazel query

```bash
# Find all targets in the repo
bazel query //...

# Find all test targets
bazel query 'kind(".*_test rule", //...)'

# Find all cc_library targets
bazel query 'kind("cc_library", //...)'

# Find everything that depends on the shared version library
bazel query 'rdeps(//..., //libs/common:version)'

# Find the shortest dependency path between two targets
bazel query 'somepath(//apps/cpp-lib:greeter_test, //libs/common:version)'

# Find all direct dependencies of a target
bazel query 'deps(//apps/cpp-lib:greeter, 1)'

# Find all transitive dependencies (full dep graph)
bazel query 'deps(//apps/cpp-lib:greeter_test)'

# Show the dep graph as Graphviz dot format
bazel query 'deps(//apps/cpp-lib:greeter_test)' --output=graph | dot -Tsvg > deps.svg

# Find all targets that would be affected if greeter.cc changed
bazel query 'rdeps(//..., //apps/cpp-lib:greeter)'

# Find targets using a specific rule kind
bazel query 'kind("go_binary", //...)'

# Find all targets with a specific tag
bazel query 'attr("tags", "smoke", //...)'
```

---

## bazel cquery (configured targets)

`cquery` understands `select()` and platform configurations. Use it when you need to know what actually gets built, not just what exists.

```bash
# Show the configured output files for a target
bazel cquery --output=files //apps/go-service:go-service

# Show the label of a configured target
bazel cquery '//apps/go-service:go-service' \
  --output=starlark \
  --starlark:expr='target.label'

# Show all transitive deps for a specific platform
bazel cquery 'deps(//apps/go-service:go-service)' \
  --platforms=//platforms:linux_amd64

# Show what a select() resolves to for a given config
bazel cquery '//apps/go-service:go-service' --output=build
```

---

## bazel aquery (action graph)

`aquery` reveals the actual commands Bazel will run. Useful for debugging hermetic failures and understanding what inputs an action sees.

```bash
# Show all actions for a target
bazel aquery //apps/cpp-lib:greeter

# Show inputs and outputs for compile actions
bazel aquery 'mnemonic("CppCompile", //apps/cpp-lib:greeter)' --output=text

# Show the exact command line for a compile action
bazel aquery 'mnemonic("CppCompile", //apps/cpp-lib:greeter)' \
  --output=text 2>&1 | grep "Arguments:"

# Show all actions that read a specific file
bazel aquery 'inputs(".*greeter.cc", //apps/cpp-lib:...)'

# Show the full action graph as proto
bazel aquery //apps/go-service:go-service --output=proto > actions.pb
```

---

## Affected Targets in CI

The "affected targets" pattern runs only tests that touch changed code:

```bash
# Find packages changed in this PR
CHANGED=$(git diff --name-only origin/main...HEAD \
  | xargs -I{} dirname {} | sort -u)

# Convert to Bazel labels
LABELS=$(echo "$CHANGED" | sed 's|^|//|; s|$|:all|')

# Find all rdeps (everything that could break)
for pkg in $LABELS; do
  bazel query "rdeps(//..., ${pkg})"
done | sort -u
```

---

## Useful Query Flags

```bash
--output=label        # just the labels (default)
--output=label_kind   # label + rule kind
--output=build        # BUILD file representation
--output=graph        # Graphviz dot format
--output=xml          # XML (for tooling)
--keep_going          # don't stop on first error
--universe_scope=//.. # scope for rdeps queries
```
