---
title: YubiKey
description: Hardware-backed authentication notes.
---

YubiKeys are used for OpenPGP, SSH FIDO2 keys, sudo authentication, LUKS2, and age recovery
workflows.

## OpenPGP

Inspect card state:

```bash
gpg --card-status
```

Manage card settings:

```bash
gpg --card-edit
```

## FIDO2 PIN

```bash
ykman fido access change-pin
```

## SSH Key

```bash
ssh-keygen -t ed25519-sk -N "" -C "johnson@mimir" -f ~/.ssh/id_mimir
```

## LUKS2

```bash
sudo systemd-cryptenroll --fido2-device=auto /dev/<device>
```

For the original compact notes, see `docs/YUBIKEY.md`.
