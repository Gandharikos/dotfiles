---
title: Architecture
description: How the repository is organized.
---

The flake is split into small modules and assembled through `flake-parts`. Project-specific helpers
live under `lib/`, while platform modules live under `modules/`.

## Top-Level Layout

- `flake.nix` defines inputs and delegates outputs to `flake/`.
- `flake/` contains flake-parts modules for hosts, packages, formatter, templates, development
  shell, and checks.
- `hosts/` contains machine entry points.
- `users/` contains per-user Home Manager configuration.
- `modules/` contains reusable NixOS, Darwin, Home Manager, and common modules.
- `config/` stores application configuration managed by the flake.
- `secrets/` stores encrypted SOPS data.
- `docs/` contains operational notes and the documentation site.

## Host Model

Hosts are the public entry points for system builds. A host usually imports hardware configuration,
platform modules, user configuration, and any services that should be enabled on that machine.

## Module Model

The repository favors small modules with explicit options. Shared behavior goes under
`modules/common/`, platform-specific behavior goes under `modules/nixos/` or `modules/darwin/`, and
user-facing Home Manager behavior lives under `users/`.

## Workstation Scheduler

`modules/nixos/services/system/scheduler.nix` enables `services.scx-loader` only for workstation
hosts. It starts `scx_bpfland` from `pkgs.scx.rustscheds` using `config.default_sched` and
`schedsPackages`. Other device types leave the loader disabled. The BPF JIT setting in
`modules/nixos/kernel/sysctl.nix` follows the same enable flag.

This replaces the removed `services.scx` module. The systemd service is now `scx_loader.service`,
not `scx.service`; the loader also provides D-Bus control with polkit authorization. Configuration
assertions are covered by `tests/scheduler.nix`. Evaluation and builds do not activate the
scheduler; after switching on an enabled workstation, check `systemctl status scx_loader` and
`/sys/kernel/sched_ext/state` to verify runtime state.

## Flake Outputs

The flake exposes system configurations, packages, templates, formatter support, and development
tooling. Use `nix flake show` to inspect the current output set:

```bash
nix flake show
```
