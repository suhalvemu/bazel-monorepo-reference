#include "apps/cpp-lib/greeter.h"
#include "libs/common/version.h"

namespace example {

Greeter::Greeter(std::string name) : name_(std::move(name)) {}

std::string Greeter::Greet() const {
    return "Hello from C++, " + name_ + "! (" + common::GetBuildInfo() + ")";
}

}  // namespace example
