#!/usr/bin/env bash
# YubiKey SSH Setup Helper Script

set -e

COLOR_GREEN='\033[0;32m'
COLOR_BLUE='\033[0;34m'
COLOR_YELLOW='\033[1;33m'
COLOR_RED='\033[0;31m'
COLOR_NC='\033[0m' # No Color

# Print colored messages
info() {
  echo -e "${COLOR_BLUE}ℹ${COLOR_NC} $1"
}

success() {
  echo -e "${COLOR_GREEN}✓${COLOR_NC} $1"
}

warning() {
  echo -e "${COLOR_YELLOW}⚠${COLOR_NC} $1"
}

error() {
  echo -e "${COLOR_RED}✗${COLOR_NC} $1"
}

# Check if YubiKey is inserted
check_yubikey() {
  info "Checking YubiKey..."
  if ! ykman list &>/dev/null; then
    error "YubiKey not detected, please insert your YubiKey"
    exit 1
  fi

  SERIAL=$(ykman info 2>/dev/null | grep "Serial number" | awk '{print $3}')
  case "$SERIAL" in
  "29642951")
    YUBIKEY_NAME="aegis (YubiKey 5C Nano)"
    ;;
  "30805408")
    YUBIKEY_NAME="janus (YubiKey 5 NFC)"
    ;;
  "32226619")
    YUBIKEY_NAME="mimir (YubiKey 5C NFC)"
    ;;
  *)
    YUBIKEY_NAME="Unknown (Serial: $SERIAL)"
    ;;
  esac

  success "Detected YubiKey: $YUBIKEY_NAME"
}

# Export current SSH public key
export_pubkey() {
  info "Exporting SSH public key..."

  # Check for GPG key
  if ssh-add -L 2>/dev/null | grep -q "cardno"; then
    info "Using GPG method..."
    ssh-add -L | grep "cardno" | grep "ed25519" >/tmp/yubikey_current.pub
    success "Public key exported to: /tmp/yubikey_current.pub"
    echo
    cat /tmp/yubikey_current.pub
    return 0
  fi

  # Check for FIDO2 key
  if ssh-add -L 2>/dev/null | grep -q "sk-ssh-ed25519"; then
    info "Using FIDO2 method..."
    ssh-add -L | grep "sk-ssh-ed25519" | head -1 >/tmp/yubikey_current.pub
    success "Public key exported to: /tmp/yubikey_current.pub"
    echo
    cat /tmp/yubikey_current.pub
    return 0
  fi

  error "YubiKey SSH key not found"
  error "Ensure gpg-agent is running or FIDO2 key is generated"
  exit 1
}

# Add public key to remote host
add_to_remote() {
  local remote_host=$1

  if [ -z "$remote_host" ]; then
    error "Please specify remote host, e.g.: user@host"
    return 1
  fi

  info "Adding public key to $remote_host ..."

  if [ ! -f /tmp/yubikey_current.pub ]; then
    export_pubkey
  fi

  # Try using ssh-copy-id
  if command -v ssh-copy-id &>/dev/null; then
    if ssh-copy-id -i /tmp/yubikey_current.pub "$remote_host"; then
      success "Public key successfully added to $remote_host"
    else
      warning "ssh-copy-id failed, trying manual method..."
      manual_copy "$remote_host"
    fi
  else
    manual_copy "$remote_host"
  fi
}

# Manually copy public key
manual_copy() {
  local remote_host=$1
  info "Manually copying public key to $remote_host ..."

  if cat /tmp/yubikey_current.pub | ssh "$remote_host" 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys'; then
    success "Public key successfully added to $remote_host"
  else
    error "Unable to add public key, please do it manually:"
    echo
    echo "1. Login to remote host: ssh $remote_host"
    echo "2. Run the following commands:"
    echo "   mkdir -p ~/.ssh"
    echo "   echo '$(cat /tmp/yubikey_current.pub)' >> ~/.ssh/authorized_keys"
    echo "   chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"
  fi
}

# Test connection
test_connection() {
  local remote_host=$1

  if [ -z "$remote_host" ]; then
    error "Please specify remote host, e.g.: user@host"
    return 1
  fi

  info "Testing SSH connection to $remote_host ..."
  warning "Please touch your YubiKey when the LED blinks"
  echo

  if ssh -o ConnectTimeout=10 "$remote_host" 'echo "Connection successful!"'; then
    success "SSH connection successful!"
  else
    error "Connection failed"
    echo
    echo "Troubleshooting:"
    echo "1. Ensure public key is added to remote host"
    echo "2. Check if YubiKey is inserted"
    echo "3. Try touching the YubiKey"
    echo "4. Check if gpg-agent is running: gpg-connect-agent /bye"
  fi
}

# Batch add to multiple hosts
batch_add() {
  info "Batch adding public key to your NixOS hosts..."

  export_pubkey

  local hosts=(
    "johnson@sigurd.local"
    "johnson@ymir.local"
    "johnson@loki.local"
    "johnson@nidhogg.local"
  )

  for host in "${hosts[@]}"; do
    echo
    info "Processing $host ..."
    if ping -c 1 -W 2 "${host#*@}" &>/dev/null; then
      add_to_remote "$host"
    else
      warning "Cannot reach $host, skipping"
    fi
  done

  success "Batch add complete"
}

# Show help information
show_help() {
  cat <<EOF
YubiKey SSH Setup Helper Script

Usage: $0 <command> [options]

Commands:
  check              - Check YubiKey status
  export             - Export current SSH public key
  add <user@host>    - Add public key to remote host
  test <user@host>   - Test SSH connection
  batch              - Batch add to all NixOS hosts
  copy               - Copy public key to clipboard

Examples:
  $0 check                           # Check YubiKey
  $0 export                          # Export public key
  $0 add johnson@sigurd.local        # Add to sigurd
  $0 test johnson@sigurd.local       # Test connection
  $0 batch                           # Batch add to all hosts
  $0 copy                            # Copy public key

EOF
}

# Copy public key to clipboard
copy_to_clipboard() {
  if [ ! -f /tmp/yubikey_current.pub ]; then
    export_pubkey
  fi

  if command -v pbcopy &>/dev/null; then
    cat /tmp/yubikey_current.pub | pbcopy
    success "Public key copied to clipboard (macOS)"
  elif command -v xclip &>/dev/null; then
    cat /tmp/yubikey_current.pub | xclip -selection clipboard
    success "Public key copied to clipboard (Linux)"
  elif command -v wl-copy &>/dev/null; then
    cat /tmp/yubikey_current.pub | wl-copy
    success "Public key copied to clipboard (Wayland)"
  else
    warning "Clipboard tool not found, please copy manually:"
    cat /tmp/yubikey_current.pub
  fi
}

# Main logic
main() {
  case "${1:-help}" in
  check)
    check_yubikey
    ;;
  export)
    check_yubikey
    export_pubkey
    ;;
  add)
    check_yubikey
    add_to_remote "$2"
    ;;
  test)
    check_yubikey
    test_connection "$2"
    ;;
  batch)
    check_yubikey
    batch_add
    ;;
  copy)
    check_yubikey
    copy_to_clipboard
    ;;
  help | --help | -h)
    show_help
    ;;
  *)
    error "Unknown command: $1"
    echo
    show_help
    exit 1
    ;;
  esac
}

main "$@"
