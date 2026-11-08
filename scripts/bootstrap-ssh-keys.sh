#!/usr/bin/env bash
set -euo pipefail
umask 077

if [[ $# != 2 || ! $2 =~ ^[a-zA-Z0-9_-][a-zA-Z0-9._-]*$ ]]; then
  echo "Usage: bootstrap-ssh-keys.sh <core-secret-directory> <host>" >&2
  exit 2
fi
core=$1
host=$2
work=$(mktemp -d)
user_staged=
host_staged=
cleanup() {
  rm -rf -- "$work"
  if [[ -n $user_staged ]]; then
    rm -f -- "$user_staged"
  fi
  if [[ -n $host_staged ]]; then
    sudo rm -rf -- "$host_staged"
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

validate_key() {
  local private=$1 public=$2 label=$3
  local actual_type actual_key expected_type expected_key _
  if ! ssh-keygen -y -P '' -f "$private" >"$private.pub"; then
    echo "Invalid $label private key; existing keys were not changed" >&2
    return 1
  fi
  read -r actual_type actual_key _ <"$private.pub"
  read -r expected_type expected_key _ <"$public"
  if [[ $actual_type != ssh-ed25519 || "$actual_type $actual_key" != "$expected_type $expected_key" ]]; then
    echo "$label key does not match its repository public key; existing keys were not changed" >&2
    return 1
  fi
}

# Validate both decryptions before touching either live key.
sops -d --extract '["data"]' "$core/id_ed25519.yaml" >"$work/user-key"
sops -d --extract '["data"]' "$core/$host.yaml" >"$work/host-key"
validate_key "$work/user-key" "$core/id_ed25519.pub" user
validate_key "$work/host-key" "$core/$host.pub" host
sudo -v

install -d -m 700 "$HOME/.ssh"
sudo install -d -m 755 /etc/ssh
if [[ -d $HOME/.ssh/id_ed25519 ]] || sudo test -d /etc/ssh/ssh_host_ed25519_key || sudo test -d /etc/ssh/ssh_host_ed25519_key.pub; then
  echo "A key destination is a directory; refusing to replace it" >&2
  exit 1
fi

# Stage on each destination filesystem so replacement is an atomic rename.
user_staged=$(mktemp "$HOME/.ssh/.id_ed25519.XXXXXX")
host_staged=$(sudo mktemp -d /etc/ssh/.bootstrap-ssh.XXXXXX)
install -m 600 "$work/user-key" "$user_staged"
sudo install -m 600 "$work/host-key" "$host_staged/ssh_host_ed25519_key"
sudo install -m 644 "$core/$host.pub" "$host_staged/ssh_host_ed25519_key.pub"

sudo mv -f -- "$host_staged/ssh_host_ed25519_key.pub" /etc/ssh/ssh_host_ed25519_key.pub
sudo mv -f -- "$host_staged/ssh_host_ed25519_key" /etc/ssh/ssh_host_ed25519_key
mv -f -- "$user_staged" "$HOME/.ssh/id_ed25519"
echo "SSH keys validated and installed; no services were restarted"
