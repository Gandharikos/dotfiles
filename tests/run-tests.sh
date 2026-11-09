#!/usr/bin/env bash
set -euo pipefail

mode=${1:-unit}
if [[ $# -gt 1 || ($mode != unit && $mode != integration) ]]; then
  echo "Usage: run-tests.sh [unit|integration]" >&2
  exit 2
fi
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"
export PYTHONDONTWRITEBYTECODE=1

# Default tests must not depend on externally supplied integration binaries.
unset SING_BOX SUB2SINGBOX
if [[ $mode == integration ]]; then
  if [[ $(nix eval --impure --raw --expr builtins.currentSystem) != x86_64-linux ]]; then
    echo "Integration fixtures currently target x86_64-linux; use unit elsewhere" >&2
    exit 1
  fi
  SUB2SINGBOX="$(nix build --no-link --print-out-paths .#sub2singbox)/bin/sub2singbox"
  SING_BOX="$(nix build --no-link --print-out-paths .#nixosConfigurations.ymir.pkgs.sing-box)/bin/sing-box"
  export SUB2SINGBOX SING_BOX
fi

python3 -m unittest discover -s tests -v
nix --extra-experimental-features pipe-operators eval --impure --json --file tests/networking.nix checks
nix --extra-experimental-features pipe-operators eval --impure --json --file tests/dae.nix
nix --extra-experimental-features pipe-operators eval --impure --json --file tests/proxy-backends.nix
nix --extra-experimental-features pipe-operators eval --impure --json --file tests/aerospace.nix
nix --extra-experimental-features pipe-operators eval --impure --json --file tests/scheduler.nix
nix --extra-experimental-features pipe-operators eval --impure --json --file tests/fastfetch.nix
for backend in sing-box mihomo; do
  nix --extra-experimental-features pipe-operators eval --impure --json \
    --file tests/proxy-profile.nix --argstr backend "$backend" checks
  nix --extra-experimental-features pipe-operators eval --impure --json \
    --file tests/proxy-profile.nix --argstr backend "$backend" \
    --argstr hostname custom-endpoint --arg webUI false checks
done
nix --extra-experimental-features pipe-operators eval --impure --raw \
  --file tests/test_storage_configuration.nix drvPath
printf '\n'

if [[ $mode == integration ]]; then
  bash tests/test-tailnet-routing.sh
  nix --extra-experimental-features pipe-operators build --impure --no-link \
    --file tests/test_restic_prepare.nix
fi
