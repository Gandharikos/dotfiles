# SSH Configuration with YubiKey FIDO2

## Overview

Unified SSH configuration module supporting:

- Traditional SSH keys (id_ed25519)
- YubiKey FIDO2 hardware authentication
- Automatic fallback mechanism
- Pre-configured host aliases

## Quick Start

### Step 1: Configure YubiKeys

YubiKey names are defined in `modules/common/my/yubikey.nix`:

```nix
my.yubikey = {
  enable = true;
  names = [
    "aegis" # YubiKey 5C Nano (Serial: 29642951) - Portable
    "janus" # YubiKey 5 NFC (Serial: 30805408) - Backup
    "mimir" # YubiKey 5C NFC (Serial: 32226619) - Primary
  ];
};
```

### Step 2: Enable SSH Configuration

Edit `hosts/tyr/default.nix` (or your host config):

```nix
{
  my.ssh = {
    enable = true;
    enableFido2 = true;  # true=FIDO2 only, false=traditional
  };

  # Disable GPG SSH support (important!)
  my.security.gpg = {
    enable = true;
    enableSshSupport = false;
  };
}
```

### Step 2: Rebuild System

```bash
cd ~/.dotfiles
just switch
```

### Step 3: Verify Configuration

```bash
# Check key order
ssh -G github.com | grep identityfile

# Test SSH connection
ssh -T git@github.com
```

---

## Configuration Options

### Option 1: FIDO2 Only (Maximum Security)

```nix
my.ssh.enableFido2 = true;
```

**Characteristics:**

- ⭐⭐⭐⭐⭐ Maximum security
- ⚠️ Must have YubiKey to SSH
- ✅ Keys from my.yubikey.names
- ✅ Suitable for production environments

**Key trial order:**

```
Keys from my.yubikey.names (in order):
1. ~/.ssh/id_aegis  (FIDO2)
2. ~/.ssh/id_janus  (FIDO2)
3. ~/.ssh/id_mimir  (FIDO2)
❌ No fallback
```

### Option 2: Traditional SSH Keys

```nix
my.ssh.enableFido2 = false;
```

**Characteristics:**

- ⭐⭐⭐ Traditional SSH authentication
- ✅ Only use id_ed25519
- ✅ No YubiKey required
- ✅ Suitable for development environments

**Key trial order:**

```
1. ~/.ssh/id_ed25519 ✅
```

---

## Generate FIDO2 Keys (For Options 1 & 2)

### Generate keys for each YubiKey

```bash
# Generate FIDO2 resident keys
ssh-keygen -t ed25519-sk -O resident -O verify-required -C "johnson@aegis" -f ~/.ssh/id_aegis
ssh-keygen -t ed25519-sk -O resident -O verify-required -C "johnson@janus" -f ~/.ssh/id_janus
ssh-keygen -t ed25519-sk -O resident -O verify-required -C "johnson@mimir" -f ~/.ssh/id_mimir

# Each requires: Touch YubiKey → Enter PIN → Touch again

# Change YubiKey PIN (if still default 123456)
ykman fido access change-pin

# Copy public keys to project
cp ~/.ssh/id_{aegis,janus,mimir}.pub ~/.dotfiles/secrets/core/keys/

# Rebuild
cd ~/.dotfiles && just switch

# Add to servers
ssh-copy-id -i ~/.ssh/id_aegis.pub user@server
# Or batch add
~/.dotfiles/scripts/yubikey-ssh-setup.sh batch

# Add to GitHub
gh ssh-key add ~/.ssh/id_aegis.pub --title "YubiKey Aegis"
gh ssh-key add ~/.ssh/id_janus.pub --title "YubiKey Janus"
gh ssh-key add ~/.ssh/id_mimir.pub --title "YubiKey Mimir"
```

---

## YubiKey Management

### Your YubiKeys

| Name  | Serial   | Type            | Purpose         |
| ----- | -------- | --------------- | --------------- |
| aegis | 29642951 | YubiKey 5C Nano | Portable/Travel |
| janus | 30805408 | YubiKey 5 NFC   | Backup/Office   |
| mimir | 32226619 | YubiKey 5C NFC  | Primary/Daily   |

### Identify Current YubiKey

```bash
# Quick identification
identify-yubikey

# Manual check
ykman info | grep "Serial number"
```

### Switch YubiKey

```bash
# Simply unplug and plug different YubiKey
# SSH will automatically use the inserted one
```

---

## Pre-configured Hosts

The following host aliases are pre-configured:

```bash
ssh loki      # → loki.local
ssh sigurd    # → sigurd.local
ssh ymir      # → ymir.local
ssh nidhogg   # → nidhogg.local

git clone git@github.com:user/repo.git  # GitHub
```

---

## Usage Examples

### FIDO2 Mode (enableFido2 = true)

```bash
# Must have YubiKey
$ identify-yubikey
✓ Detected YubiKey: mimir ✓

$ ssh sigurd
→ Touch YubiKey
✅ Connected (using id_mimir FIDO2)

# Without YubiKey
$ ssh sigurd
❌ Failed: "No FIDO authenticator found"
```

### Traditional Mode (enableFido2 = false)

```bash
# With or without YubiKey
$ ssh sigurd
✅ Connected immediately (using id_ed25519)
```

---

## Troubleshooting

### "sign_and_send_pubkey: signing failed for ED25519-SK"

**Cause:** YubiKey not touched or timeout

**Solution:**

1. Wait for YubiKey LED to blink
2. Touch the metal contact
3. Retry connection

### "Provider internal returned failure"

**Cause:** Wrong PIN or not set

**Solution:**

```bash
# Check FIDO2 info
ykman fido info

# Change PIN
ykman fido access change-pin

# If forgot PIN, reset (deletes all FIDO2 credentials)
ykman fido reset  # ⚠️ Use carefully
```

### "No FIDO device available"

**Cause:** YubiKey not detected

**Solution:**

```bash
# Check YubiKey
ykman list

# Check FIDO2 status
ykman fido info

# macOS: Check USB connection
system_profiler SPUSBDataType | grep -A 5 Yubikey

# Linux/NixOS: Restart pcscd
sudo systemctl restart pcscd
```

### SSH still uses GPG Agent

**Cause:** GPG SSH support not disabled

**Solution:**

```bash
# Ensure GPG config has
my.security.gpg.enableSshSupport = false;

# Restart GPG agent
gpgconf --kill gpg-agent
exec $SHELL

# Verify
echo $SSH_AUTH_SOCK  # Should not contain gpg-agent
```

---

## Security Best Practices

### 1. Change Default PIN

```bash
# Change FIDO2 PIN (default: 123456)
ykman fido access change-pin

# Use strong PIN (8+ digits)
```

### 2. Backup Strategy

- **Primary:** mimir (daily use)
- **Backup 1:** janus (office safe)
- **Backup 2:** aegis (home secure location)

### 3. Test All YubiKeys

```bash
# Ensure each YubiKey works
for key in aegis janus mimir; do
  echo "Test $key..."
  # Insert corresponding YubiKey
  read -p "Insert $key and press Enter"
  ssh -T git@github.com || echo "Failed!"
done
```

### 4. Regular Backups

```bash
# Backup public keys
mkdir -p ~/Documents/ssh-backups
cp ~/.ssh/id_*.pub ~/Documents/ssh-backups/
cp ~/.dotfiles/secrets/core/keys/id_*.pub ~/Documents/ssh-backups/

# Document YubiKey purposes
cat > ~/Documents/ssh-backups/mapping.txt <<EOF
aegis (29642951): Travel, temporary workstations
janus (30805408): Development servers, testing
mimir (32226619): Production servers, GitHub
EOF
```

---

## Files and Locations

```
~/.dotfiles/
├── modules/
│   ├── common/my/yubikey.nix              # YubiKey identifiers config
│   └── home/cli/security/ssh.nix          # Main SSH module
├── secrets/core/
│   ├── id_ed25519.pub                     # Regular SSH public key
│   └── keys/
│       ├── id_aegis.pub                   # Aegis FIDO2 public key
│       ├── id_janus.pub                   # Janus FIDO2 public key
│       ├── id_mimir.pub                   # Mimir FIDO2 public key
│       ├── YUBIKEYS.md                    # YubiKey serial mapping
│       └── identify-yubikey.sh            # Identification script
├── scripts/yubikey-ssh-setup.sh           # Setup helper script
├── examples/ssh-config.nix                # Configuration examples
└── docs/SSH_CONFIG.md                     # This document

~/.ssh/
├── id_ed25519                             # Regular private key
├── id_ed25519.pub -> (nix store)          # Linked from nix store
├── id_aegis.pub -> (nix store)            # Linked from nix store
├── id_janus.pub -> (nix store)            # Linked from nix store
├── id_mimir.pub -> (nix store)            # Linked from nix store
└── config                                 # Generated by Home Manager

~/.local/bin/
└── identify-yubikey                       # YubiKey ID helper
```

---

## Configuration Comparison

| Feature                 | FIDO2 Mode<br/>(enableFido2=true) | Traditional Mode<br/>(enableFido2=false) |
| ----------------------- | --------------------------------- | ---------------------------------------- |
| **Security**            | ⭐⭐⭐⭐⭐                        | ⭐⭐⭐                                   |
| **Convenience**         | ⭐⭐                              | ⭐⭐⭐⭐⭐                               |
| **YubiKey Required**    | ✅ Yes                            | ❌ No                                    |
| **YubiKey Loss Impact** | ⚠️ Need backup                    | ➖ No impact                             |
| **Use Case**            | Production                        | Development                              |

---

## Quick Reference

```bash
# Check configuration
ssh -G github.com | grep identityfile

# Identify YubiKey
identify-yubikey

# List loaded keys
ssh-add -L

# Test GitHub
ssh -T git@github.com

# Change YubiKey PIN
ykman fido access change-pin

# Setup helper
~/.dotfiles/scripts/yubikey-ssh-setup.sh help
```

---

## See Also

- **Configuration Example:** `examples/ssh-config.nix`
- **YubiKey Mapping:** `secrets/core/keys/YUBIKEYS.md`
- **Module Source:** `modules/home/cli/security/ssh.nix`
- **Setup Script:** `scripts/yubikey-ssh-setup.sh`
