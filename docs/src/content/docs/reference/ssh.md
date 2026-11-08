---
title: SSH
description: SSH and YubiKey FIDO2 notes.
---

The SSH module supports traditional `id_ed25519` keys and YubiKey-backed FIDO2 keys.

## Enable SSH

In a host configuration:

```nix
{
  home-manager.users.johnson.my.ssh = {
    enable = true;
    enableFido2 = true;
  };
}
```

Inside a Home Manager module, use `my.ssh` directly. The shared options live in
`users/johnson/home/cli/security/ssh.nix`; personal hosts and keys live in
`users/johnson/home/ssh-hosts.nix`.

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
