# SOPS Secret Management

This repository uses SOPS with `sops-nix` to manage encrypted user, host, and service secrets. The
current design uses SSH-derived age recipients for normal operation and a PGP key, usually backed by
a YubiKey, for bootstrap and recovery.

## Key Model

The encryption recipients are declared in `.sops.yaml`.

### User Recipient

`johnson_age` is derived from the regular user SSH public key:

```bash
ssh-to-age < secrets/johnson/core/id_ed25519.pub
```

The result should match the `johnson_age` entry in `.sops.yaml`:

```text
age1dru9s2hakwc4zjzh64z35nkt7uemgq4xc0vz5v5m8s2juy0edugs5esp5j
```

The same check can be run against the live key:

```bash
ssh-keygen -lf secrets/johnson/core/id_ed25519.pub
ssh-keygen -lf ~/.ssh/id_ed25519.pub
ssh-to-age < ~/.ssh/id_ed25519.pub
```

### Host Recipients

Each host age recipient is derived from that host's SSH host public key:

```bash
ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
```

On persisted NixOS hosts, the private host key is also copied to:

```text
/persist/etc/ssh/ssh_host_ed25519_key
```

System-level `sops-nix` uses this SSH host key via `modules/common/environment/secrets.nix`.

### PGP Recipient

The PGP recipient is:

```text
E23E274D412D4C761A871B1E776C7FC245E58F55
```

This key is kept as a bootstrap and recovery path. It is especially important for secrets that
contain the SSH keys needed to unlock other age-encrypted secrets.

## Secret Layout

### `secrets/johnson/`

User-specific secrets. These are encrypted to:

- `johnson_age`
- the PGP recipient

The matching rule is intentionally limited to files directly under `secrets/johnson/`.
Subdirectories such as `secrets/johnson/core/` must use their own more specific rules.

Home Manager decrypts these using:

```nix
sops.age.sshKeyPaths = [ "${home}/.ssh/id_ed25519" ];
```

Important bootstrap note: `secrets/johnson/core/id_ed25519.yaml` contains the same private SSH key
that produces `johnson_age`. That means this file cannot be bootstrapped using only `johnson_age`,
because the required private key is inside the encrypted file. The core rule keeps this file
PGP-only.

### `secrets/johnson/core/`

Core host-level secrets, such as SSH host private keys. These are encrypted to PGP only by the
current `.sops.yaml` rule.

This is intentional: host keys are needed before the host can decrypt system-level age secrets. The
directory lives under `secrets/johnson/` because the bootstrap key owner is the `johnson` identity,
but it has a more specific SOPS rule than ordinary user secrets.

### `secrets/services/`

System and service secrets. These are encrypted to:

- all host age recipients
- the PGP recipient

NixOS decrypts these using the host SSH private key:

```text
/etc/ssh/ssh_host_ed25519_key
```

or, on persisted systems:

```text
/persist/etc/ssh/ssh_host_ed25519_key
```

## Common Commands

Edit a secret:

```bash
sops secrets/services/default.yaml
sops secrets/johnson/default.yaml
```

Set a value non-interactively:

```bash
sops --in-place set secrets/services/default.yaml '["my_key"]' '"my-secret-value"'
```

Update recipients after changing `.sops.yaml` or moving a secret:

```bash
sops updatekeys -y secrets/johnson/core/id_ed25519.yaml
sops updatekeys -y secrets/services/default.yaml
```

Decrypt without printing sensitive data:

```bash
sops -d secrets/services/default.yaml >/dev/null
```

For user secrets, manual decryption with an SSH-derived age key may need the SSH identity path set
explicitly:

```bash
SOPS_AGE_SSH_PRIVATE_KEY_FILE="$HOME/.ssh/id_ed25519" \
  sops -d secrets/johnson/default.yaml >/dev/null
```

## Local Initialization

Use this when setting up an existing machine that already has access to the PGP key or an existing
user SSH key.

1. Verify the local user SSH key:

   ```bash
   ssh-keygen -lf ~/.ssh/id_ed25519.pub
   ssh-to-age < ~/.ssh/id_ed25519.pub
   ```

2. Decrypt the user and host SSH keys:

   ```bash
   just init-local <host>
   ```

   This writes:

   ```text
   ~/.ssh/id_ed25519
   /etc/ssh/ssh_host_ed25519_key
   ```

3. Rebuild:

   ```bash
   just switch <host>
   ```

## Remote Initialization

`just init-remote <host> <ip>` assumes the local username and remote username are the same. This
matters because Home Manager profiles and Nix per-user profile directories are created for that
exact user.

The command copies:

- the user SSH key from `secrets/<user>/core/id_ed25519.yaml`
- the host SSH key from `secrets/<user>/core/<host>.yaml`

It installs them into the live remote paths only. If a host persists `/etc/ssh`, the user home, or
the Nix profile directory through mounts or bind mounts, writing those live paths is enough and does
not require `init-remote` to know about `/persist`.

Run:

```bash
just init-remote <host> <ip>
```

Then deploy or switch the host:

```bash
just deploy <host> switch
```

## Adding A New Host

1. Generate or collect the host SSH public key:

   ```bash
   ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
   ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
   ```

2. Add the resulting age recipient to `.sops.yaml`.

3. Add it to the `secrets/services/` creation rule.

4. Re-key service secrets:

   ```bash
   sops updatekeys -y secrets/services/default.yaml
   sops updatekeys -y secrets/services/clash.yaml
   ```

5. Store the host private key under `secrets/johnson/core/<host>.yaml` if this repository should
   bootstrap that host.

## Adding A New User SSH Key

1. Generate the key:

   ```bash
   ssh-keygen -t ed25519 -C "$USER" -f ~/.ssh/id_ed25519
   ```

2. Copy the public key into the repository:

   ```bash
   cp ~/.ssh/id_ed25519.pub secrets/johnson/core/id_ed25519.pub
   ```

3. Derive the age recipient:

   ```bash
   ssh-to-age < secrets/johnson/core/id_ed25519.pub
   ```

4. Update `.sops.yaml`.

5. Re-key user secrets:

   ```bash
   sops updatekeys -y secrets/johnson/default.yaml
   ```

For `secrets/johnson/core/id_ed25519.yaml`, keep the core PGP-only rule. Otherwise a fresh machine
can end up needing the same SSH private key that is still inside the encrypted file.

## Verification

Check that a user secret can decrypt with the local SSH key:

```bash
SOPS_AGE_SSH_PRIVATE_KEY_FILE="$HOME/.ssh/id_ed25519" \
  sops -d secrets/johnson/default.yaml >/dev/null
```

Check that a service secret can decrypt with a host key:

```bash
SOPS_AGE_SSH_PRIVATE_KEY_FILE="/etc/ssh/ssh_host_ed25519_key" \
  sops -d secrets/services/default.yaml >/dev/null
```

Check the PGP/YubiKey recovery path:

```bash
sops -d --extract '["data"]' secrets/johnson/core/id_ed25519.yaml >/dev/null
```

If this command times out, SOPS found the PGP recipient but GPG or the YubiKey did not complete the
decrypt operation.

## Troubleshooting

### `age: identity did not match any of the recipients`

The SSH private key used for decryption does not match the age recipient in the file.

Verify:

```bash
ssh-to-age < ~/.ssh/id_ed25519.pub
```

Then retry with:

```bash
SOPS_AGE_SSH_PRIVATE_KEY_FILE="$HOME/.ssh/id_ed25519" sops -d <file>
```

### `gpg: public key decryption failed: Timeout`

SOPS tried the PGP recipient, but GPG did not finish. Common causes:

- YubiKey is not inserted.
- GPG agent is stuck.
- Pinentry did not appear or was dismissed.
- Touch confirmation timed out.

Useful checks:

```bash
gpg --card-status
gpgconf --kill gpg-agent
sops -d <file> >/dev/null
```

### `secrets/johnson/core/id_ed25519.yaml` cannot decrypt with age

This is expected. The file lives under the core bootstrap rule and is kept PGP-only. Use the
PGP/YubiKey recovery path first, then install the SSH key locally with:

```bash
just init-local <host>
```
