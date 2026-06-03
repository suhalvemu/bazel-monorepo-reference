# defs.bzl — reusable Starlark macros for this monorepo.
#
# Macros run at LOADING time (when BUILD files are parsed).
# Rules run at ANALYSIS time (when the dependency graph is evaluated).
# This distinction matters: macros can call rules, but not vice versa.

load("@rules_cc//cc:defs.bzl", "cc_library", "cc_test")

def cc_library_with_test(name, srcs, hdrs, test_srcs, deps = [], test_deps = [], **kwargs):
    """Macro: declares a cc_library and its cc_test in one call.

    Reduces boilerplate in BUILD files where every library has a paired test.
    The test target is named <name>_test.

    Usage:
        cc_library_with_test(
            name = "greeter",
            srcs = ["greeter.cc"],
            hdrs = ["greeter.h"],
            test_srcs = ["greeter_test.cc"],
            test_deps = ["@googletest//:gtest_main"],
        )
    """
    cc_library(
        name = name,
        srcs = srcs,
        hdrs = hdrs,
        deps = deps,
        **kwargs
    )

    cc_test(
        name = name + "_test",
        srcs = test_srcs,
        deps = [":" + name] + test_deps,
        size = "small",
    )
