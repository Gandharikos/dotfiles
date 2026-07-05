---
title: SSH
description: SSH and YubiKey FIDO2 notes.
---

The SSH module supports traditional `id_ed25519` keys and YubiKey-backed FIDO2 keys.

## Enable SSH

```nix
{
  dot.ssh = {
    enable = true;
    enableFido2 = true;
  };
}
```

When FIDO2 is enabled, keys are generated per YubiKey label and tried in the configured order.

## Verify

```bash
ssh -G github.com | grep identityfile
ssh -T git@github.com
```

## Generate FIDO2 Keys

```bash
ssh-keygen -t ed25519-sk -O resident -O verify-required -C "johnson@mimir" -f ~/.ssh/id_mimir
```

For the full operational guide, see `docs/SSH_CONFIG.md`.
