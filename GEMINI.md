# Gemini Context: Nix Dotfiles

This repository contains a modular NixOS and macOS (nix-darwin) configuration managed with Nix
Flakes, `flake-parts`, and `home-manager`.

## Project Overview

- **Architecture:** Modular design with separation between system configurations (`hosts/`), shared
  modules (`modules/`), custom libraries (`lib/`), and user-specific settings (`users/`).
- **Technologies:** Nix, Nix Flakes, `flake-parts`, `home-manager`, `sops-nix` (secrets), `disko`
  (partitioning), `just` (command runner).
- **Target Platforms:** NixOS (Linux) and nix-darwin (macOS).
- **Key Feature:** A custom library (`lib.dot`) used for deep merging attributes, scanning paths,
  and standardizing user/theme options.

## Directory Structure

- `hosts/`: Machine-specific configurations (e.g., `loki`, `sigurd`, `ymir`).
- `modules/`:
  - `common/`: Modules shared across NixOS and Darwin.
  - `nixos/`: NixOS-specific modules.
  - `darwin/`: nix-darwin-specific modules.
  - `home/`: Home Manager modules.
- `lib/`: Custom Nix helper functions (merged into `lib.dot`).
- `config/`: Non-Nix configuration files (e.g., Neovim, WezTerm, Fish) that are symlinked or managed
  by the configuration.
- `packages/`: Custom Nix packages and scripts.
- `overlays/`: Nixpkgs overlays.
- `secrets/`: Encrypted secrets managed by `sops`.
- `scripts/`: Utility shell scripts.

## Building and Running

The project uses `just` as a command runner. Key commands include:

### Rebuilding System

- `just switch`: Rebuild and switch to the current configuration for the local host.
- `just test`: Rebuild and test the configuration without making it the default boot entry.
- `just rollback`: Roll back to the previous system generation.

### Development & Maintenance

- `just check`: Run `nix flake check` and `statix` linting.
- `just fmt`: Format all Nix files using the configured formatter.
- `just update`: Update flake inputs.
- `just dev <name>`: Enter a development shell.
- `just gc`: Run garbage collection to clean up old generations.

### Config Management (config/ directory)

- `just cfg <program>`: Sync configuration for a specific program from the `config/` directory to
  `~/.config/`.
- `just add <program>`: Move an existing config from `~/.config/` into the `config/` directory for
  management.

### Secrets

- `just init-local`: Decrypt and initialize local SSH keys and host keys using `sops`.

## Development Conventions

- **Modular Imports:** Use `lib.dot.scanPaths ./.` in `default.nix` files to automatically import
  all sibling `.nix` files in a directory.
- **Library Usage:** Prefer functions in `lib.dot` (defined in `lib/`) for complex logic like
  merging or user creation.
- **Deep Merging:** Use `lib.dot.deepMerge` when combining complex attribute sets where standard Nix
  merging might be insufficient.
- **Secrets:** Never commit plain-text secrets. Use `sops` and reference them via the `sops-nix`
  module.
- **Hardware:** Hardware-specific logic should reside in `hosts/<name>/hardware-configuration.nix`
  (usually generated) or `hosts/<name>/config.nix`.
