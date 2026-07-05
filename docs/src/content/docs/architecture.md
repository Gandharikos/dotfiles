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

## Flake Outputs

The flake exposes system configurations, packages, templates, formatter support, and development
tooling. Use `nix flake show` to inspect the current output set:

```bash
nix flake show
```
