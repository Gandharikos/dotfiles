# Qt 6 C++ Nix project template

A minimal C++20 and Qt 6 Widgets application with reproducible Nix builds, CMake, Ninja, direnv,
clang tooling, and Git hooks.

## Create a project

```console
nix flake init -t ~/.dotfiles#qt
git init
direnv allow
```

## Commands

```console
nix build
nix run
nix run . -- --version
nix develop
nix flake check
nix fmt
nix run .#generate-compile-commands
```

Inside `nix develop`, build with CMake directly:

```console
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build build
./build/qt-app
```

Entering the development shell installs the configured Git hooks. Clang-tidy runs at the `pre-push`
stage because it requires a compilation database.
