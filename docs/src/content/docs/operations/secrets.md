---
title: Secrets
description: SOPS recipient model and common secret operations.
---

Secrets are managed with SOPS and `sops-nix`. The repository uses SSH-derived age recipients for
normal host and user operation, plus a PGP recipient for bootstrap and recovery.

## Recipient Model

- User secrets under `secrets/johnson/` are encrypted to the user age recipient and the PGP
  recipient.
- Core bootstrap secrets under `secrets/johnson/core/` are PGP-only.
- Service secrets under `secrets/services/` are encrypted to host recipients and the PGP recipient.

The authoritative recipient rules live in `.sops.yaml`.

## Common Commands

Edit a secret:

```bash
sops secrets/services/default.yaml
sops secrets/johnson/default.yaml
```

Update recipients after changing `.sops.yaml`:

```bash
sops updatekeys -y secrets/services/default.yaml
```

Validate decryption without printing the secret:

```bash
sops -d secrets/services/default.yaml >/dev/null
```

## Bootstrap

Initialize local keys for an existing host:

```bash
just init-local <host>
```

Initialize a remote machine:

```bash
just init-remote <host> <ip>
```

For the longer operational notes, see the Markdown source at `docs/SOPS.md`.
