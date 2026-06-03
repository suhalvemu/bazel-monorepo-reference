#include "apps/cpp-lib/greeter.h"
#include <gtest/gtest.h>

namespace example {

TEST(GreeterTest, GreetsWithName) {
    Greeter g("Bazel");
    // Greeting embeds build info from //libs/common:version (shared library dep).
    // Use find() to check the prefix without hard-coding the full version string.
    EXPECT_NE(g.Greet().find("Hello from C++, Bazel!"), std::string::npos);
}

TEST(GreeterTest, GreetsWorld) {
    Greeter g("World");
    EXPECT_NE(g.Greet().find("Hello from C++, World!"), std::string::npos);
}

}  // namespace example
