# Repository Guidelines

## Project Structure & Module Organization

This repository is a personal Nix flake for NixOS, nix-darwin, WSL, and Home Manager. Host entry
points live in `hosts/`, reusable system modules in `modules/`, user and Home Manager configuration
in `users/`, shared Lua/Nix/application config in `config/`, overlays in `overlays/`, local packages
in `packages/`, scripts in `scripts/`, and encrypted SOPS data in `secrets/`. Flake outputs and
development integration are organized under `flake/`.

## Build, Test, and Development Commands

Use the `justfile` for common workflows:

- `just switch <host>`: rebuild and switch the target host.
- `just test <host>`: build and activate a test generation.
- `just deploy <host>`: remote rebuild with closure diff output.
- `just check`: run `nix flake check` and `statix` when available.
- `just fmt`: run the flake formatter.
- `just dev`: enter the default development shell.

For focused validation, prefer
`nix build --no-link .#nixosConfigurations.<host>.config.system.build.toplevel` or evaluate the
exact option you changed.

## Coding Style & Naming Conventions

Nix files are formatted with `nixfmt`; Lua uses Stylua with two-space indentation and 120-column
width. Shell scripts use `shfmt` with two-space indentation and should pass ShellCheck. Keep module
options under existing namespaces such as `dot.*`, `my.*`, or `programs.*`, matching nearby files.
Prefer small modules, `mkIf`-guarded config, and existing helpers from `lib.dot`.

## Testing Guidelines

There is no conventional unit-test suite for most modules. Treat evaluation and builds as the
primary tests. Run `just check` for broad validation, then build the affected host or Home Manager
activation package. For user config changes, test
`home-manager.users.<name>.home.activationPackage`; for system services, build the host toplevel.

## Commit & Pull Request Guidelines

History uses Conventional Commits, for example `feat(nvim): ...`, `fix(tmux): ...`, and
`style(theme): ...`. Keep commits focused and explain behavioral impact. Pull requests should
include a short description, affected hosts/modules, validation commands, and screenshots only for
visible UI or desktop changes.

## Security & Configuration Tips

Never commit plaintext secrets. Use SOPS-managed files under `secrets/`, and avoid hardcoding
host-specific credentials, tokens, SSH keys, or API keys in modules.
