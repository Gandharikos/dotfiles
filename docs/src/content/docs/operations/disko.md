---
title: Disko
description: Declarative disk management notes.
---

Disk layouts are declared through Disko modules under `hosts/common/disko/` and host-specific
imports.

## Install Flow

1. Boot a NixOS installer.
2. Load the host disk configuration.
3. Run Disko to partition and mount filesystems.
4. Generate hardware configuration without filesystem entries.
5. Install using the host flake output.

## Useful Commands

Run Disko through the development shell command:

```bash
disko --mode disko --flake .#<host>
```

Install through nixos-anywhere:

```bash
just install <host> <target>
```

For older step-by-step notes, see `docs/DISKO.md`.
