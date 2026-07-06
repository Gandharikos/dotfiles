---
title: Getting Started
description: First steps for reading and adapting this flake.
---

This repository is personal infrastructure. Treat it as a reference first, then copy patterns into
your own configuration deliberately.

## Prerequisites

- Nix with `nix-command` and `flakes` enabled
- Git
- `just` for the documented command shortcuts
- Host-specific hardware and disk configuration for any real NixOS install
- Access to the required SOPS keys if you want to deploy this exact repository

## Clone

```bash
git clone https://github.com/Gandharikos/dotfiles ~/.dotfiles
cd ~/.dotfiles
```

## Inspect Available Commands

```bash
just
```

The most common commands are:

```bash
just switch <host>
just test <host>
just deploy <host>
just check
just fmt
```

## Build Before Switching

Run a non-destructive build or test first:

```bash
just test <host>
```

Only switch after you have verified host names, hardware settings, disk layout, and secret access.

## Documentation Site

Run the docs locally:

```bash
cd docs
npm install
npm run dev
```

Build static docs:

```bash
npm run build
```
