#!/usr/bin/env bash
set -euo pipefail

# Pass the built ExecStartPre program from the shared profile's mihomo.service.
seed_program=${1:?Usage: test-mihomo-provider-seed.sh /nix/store/.../bin/mihomo-seed-provider}
workdir=$(mktemp -d)
trap 'rm -rf -- "$workdir"' EXIT
export STATE_DIRECTORY="$workdir/state"
export CREDENTIALS_DIRECTORY="$workdir/credentials"
mkdir -p "$STATE_DIRECTORY" "$CREDENTIALS_DIRECTORY"
seed="$CREDENTIALS_DIRECTORY/wgetcloud.yaml"
provider="$STATE_DIRECTORY/providers/wgetcloud.yaml"
marker="$STATE_DIRECTORY/providers/wgetcloud.seed-sha256"

printf 'proxies: []\n' >"$seed"
"$seed_program"
cmp "$seed" "$provider"
test "$(stat -c %a "$provider")" = 600
test "$(stat -c %a "$(dirname "$provider")")" = 700
test "$(<"$marker")" = "$(sha256sum "$seed" | cut -d ' ' -f 1)"

# A normal restart must not overwrite a newer online subscription update.
printf '# online update\nproxies: []\n' >"$provider"
cp "$provider" "$workdir/online.yaml"
"$seed_program"
cmp "$provider" "$workdir/online.yaml"

# A new encrypted snapshot deliberately replaces the cached subscription.
printf '# changed bootstrap snapshot\nproxies: []\n' >"$seed"
"$seed_program"
cmp "$seed" "$provider"

rm "$provider"
"$seed_program"
cmp "$seed" "$provider"
: >"$provider"
"$seed_program"
cmp "$seed" "$provider"
printf 'PASS: bootstrap cache, permissions, online-cache preservation, snapshot rotation, missing/empty cache recovery\n'
