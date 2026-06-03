#include "libs/common/version.h"

namespace common {

std::string GetVersion() {
    return "1.0.0";
}

std::string GetBuildInfo() {
    return "bazel-cache-rbe-examples v" + GetVersion();
}

}  // namespace common
