# SSH FIDO2 Quick Reference Card

## Your YubiKeys

| Name  | Serial   | Type            | Use Case           |
|-------|----------|-----------------|--------------------|
| aegis | 29642951 | 5C Nano (USB-C) | Portable/Travel    |
| janus | 30805408 | 5 NFC           | Backup/Secondary   |
| mimir | 32226619 | 5C NFC (USB-C)  | Primary/Daily Use  |

## Quick Commands

```bash
# Identify current YubiKey
identify-yubikey

# List available SSH keys
ssh-add -L

# Export keys from YubiKey
cd ~/.ssh && ssh-keygen -K

# Test GitHub authentication
ssh -T git@github.com

# Change YubiKey PIN
ykman fido access change-pin
```

## Generate New FIDO2 Key

```bash
ssh-keygen -t ed25519-sk -O resident -O verify-required -C "johnson@$(hostname)"
```

## Add to Remote Server

```bash
ssh-copy-id -i ~/.ssh/id_aegis.pub user@server
```

## Add to GitHub

```bash
cat ~/.ssh/id_aegis.pub | gh ssh-key add - --title "YubiKey Aegis"
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "signing failed" | Touch YubiKey when LED blinks |
| "Provider internal failure" | Enter PIN (default: 123456) |
| "No FIDO device" | Run `ykman list` to check connection |
| "Key does not contain public key" | Use `-O resident` when generating |

## Enable in Config

```nix
my.security.ssh-fido2 = {
  enable = true;
  yubikeys = [ "aegis" "janus" "mimir" ];
};
```

## File Locations

```
~/.ssh/id_aegis.pub    # Aegis public key
~/.ssh/id_janus.pub    # Janus public key
~/.ssh/id_mimir.pub    # Mimir public key
```

## Security Notes

✅ Private keys NEVER leave YubiKey
✅ Touch required for each authentication
✅ PIN required after timeout
✅ Up to 25 resident keys per YubiKey

## Default Credentials

- **FIDO2 PIN**: 123456 (CHANGE THIS!)
- **Admin PIN**: 12345678 (CHANGE THIS!)

⚠️ Change defaults: `ykman fido access change-pin`
