# YubiKey SSH Keys Mapping

This file maps YubiKey names to their serial numbers for easy identification.

## FIDO2 SSH Keys

| Name   | Serial Number | Type             | Notes                    |
|--------|---------------|------------------|--------------------------|
| aegis  | 29642951      | YubiKey 5C Nano  | Johnson Hu (verified ✓)  |
| janus  | 30805408      | YubiKey 5 NFC    | Johnson Hu (verified ✓)  |
| mimir  | 32226619      | YubiKey 5C NFC   | Johnson Hu (verified ✓)  |

## How to Identify

1. Insert YubiKey
2. Run: `ykman info | grep "Serial number"`
3. Match serial number with table above

## Key Types

- **FIDO2 keys** (`id_*.pub`): Used with `ssh-keygen -t ed25519-sk`
- **GPG keys**: Loaded via `gpg-agent` for SSH authentication

Current YubiKey (serial 32226619) is configured with:
- GPG SSH authentication (currently loaded)
- FIDO2 support (enabled)
