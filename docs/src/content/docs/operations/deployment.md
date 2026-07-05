---
title: Deployment
description: Build, switch, and remote deployment commands.
---

Deployments are handled with `just` wrappers around NixOS, nix-darwin, and remote rebuild commands.

## Local Rebuilds

```bash
just switch <host>
just boot <host>
just test <host>
```

`just test` is the safest first check because it builds and activates the system temporarily without
making it the boot default.

## Remote Deployment

```bash
just deploy <host>
```

The deploy command records the remote system generation before and after the switch, then prints a
closure diff when the generation changes.

## Checks

```bash
just check
```

This runs `nix flake check` and, when available, `statix check .`.

## Formatting

```bash
just fmt
```

The formatter is defined by the flake and should be run before committing Nix changes.
