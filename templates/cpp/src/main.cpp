#include <cstddef>
#include <iostream>
#include <span>
#include <string_view>

namespace {

[[nodiscard]] bool versionRequested(std::span<char*> arguments) noexcept {
  for (const char* value : arguments.subspan(1)) {
    const std::string_view argument{value};
    if (argument == "--version" || argument == "-v") {
      return true;
    }
  }
  return false;
}

} // namespace

int main(int argc, char** argv) {
  const std::span arguments{argv, static_cast<std::size_t>(argc)};
  if (versionRequested(arguments)) {
    std::cout << "cpp-app " << CPP_APP_VERSION << '\n';
    return 0;
  }

  std::cout << "Hello from C++20 and Nix!\n";
  return 0;
}
