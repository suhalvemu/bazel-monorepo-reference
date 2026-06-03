#include "apps/cpp-lib/greeter.h"
#include <gtest/gtest.h>

namespace example {

TEST(GreeterTest, GreetsWithName) {
    Greeter g("Bazel");
    EXPECT_EQ(g.Greet(), "Hello from C++, Bazel!");
}

TEST(GreeterTest, GreetsWorld) {
    Greeter g("World");
    EXPECT_EQ(g.Greet(), "Hello from C++, World!");
}

}  // namespace example
