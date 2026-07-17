# Qt Quick C++ Nix project template

A reusable C++23 and Qt 6 project with Qt Quick, QML, Qt Quick Controls, CMake presets, Qt Test,
Wayland support, reproducible Nix builds, direnv, clang tooling, and Git hooks.

The example uses `qt_add_qml_module()` to bundle the `QtQuickTemplate` module. `AppModel` is a C++
`QObject` registered with `QML_ELEMENT`; the interface reads and updates its `title` and `count`
properties. `Theme.qml` centralizes color, typography, spacing, shape, and motion tokens.

## Create a project

```console
nix flake init -t ~/.dotfiles#qt-quick
git init
direnv allow
```

## Develop and test

```console
nix develop
cmake --preset dev
cmake --build --preset dev
ctest --preset dev
```

Entering the development shell configures the Qt plugin and QML import paths and installs the Git
hooks. Generate a compilation database for clangd with:

```console
nix run .#generate-compile-commands
```

## Build and run with Nix

```console
nix build
nix run
nix run . -- --version
nix flake check
nix fmt
```

Qt selects the display backend automatically. To explicitly use Wayland:

```console
QT_QPA_PLATFORM=wayland nix run
```

For a display-independent startup check:

```console
QT_QPA_PLATFORM=offscreen nix run . -- --smoke-test
```
