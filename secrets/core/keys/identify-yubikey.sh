#!/usr/bin/env bash
# Quick YubiKey identification script

set -e

echo "=== Current YubiKey Information ==="
ykman info 2>/dev/null | grep -E "(Device type|Serial number|Firmware version)"

echo -e "\n=== Serial Number ==="
SERIAL=$(ykman info 2>/dev/null | grep "Serial number" | awk '{print $3}')
echo "Serial: $SERIAL"

echo -e "\n=== Mapping Check ==="
case "$SERIAL" in
    "29642951")
        echo "This is: aegis ✓"
        ;;
    "30805408")
        echo "This is: janus ✓"
        ;;
    "32226619")
        echo "This is: mimir ✓"
        ;;
    *)
        echo "Unknown YubiKey - please update YUBIKEYS.md"
        ;;
esac

echo -e "\n=== GPG Cardholder ==="
gpg --card-status 2>/dev/null | grep "Name of cardholder" || echo "No GPG card detected"

echo -e "\n=== Stored Public Keys ==="
ls -1 id_*.pub | while read key; do
    name=$(basename "$key" .pub | sed 's/id_//')
    echo "  - $name"
done
