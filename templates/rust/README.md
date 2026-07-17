# Rust Nix project template

A small Rust 2024 application with a pinned Nix development environment, Crane builds, direnv, Git
hooks, and GitHub Actions. Nix and `rust-toolchain.toml` select the same Rust toolchain.

## Create a project

```console
nix flake init -t ~/.dotfiles#rust
git init
git add .
direnv allow
```

## Develop

```console
nix develop
cargo build
cargo test
cargo clippy --all-targets -- --deny warnings
just check
```

The development shell installs Rust, rust-analyzer, `just`, `bacon`, and the configured Git hooks.
Use `just watch` to rebuild and run automatically while editing.

## Build and run with Nix

```console
nix build
nix run
nix run . -- --version
nix flake check
nix fmt
```

Crane builds dependencies separately from the application, so source-only changes can reuse the
dependency build. Add native libraries shared by the package and development shell to `commonArgs`
in `flake.nix`.
