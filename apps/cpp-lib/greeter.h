#pragma once
#include <string>

namespace example {

class Greeter {
 public:
  explicit Greeter(std::string name);
  std::string Greet() const;

 private:
  std::string name_;
};

}  // namespace example
