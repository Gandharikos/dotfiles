#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
export ROUTING_SCRIPT="$root/scripts/mihomo-tailnet-routing.sh"

# No host routing changes or external connectivity: all interfaces are dummy
# devices in an unprivileged user/network namespace.
unshare --user --map-root-user --net bash <<'TEST'
set -euo pipefail
ip link set lo up
for device in uplink tailscale0 mihomo; do
  ip link add "$device" type dummy
  ip link set "$device" up
 done
ip addr add 192.0.2.2/24 dev uplink
ip -6 addr add 2001:db8:1::2/64 dev uplink nodad
ip addr add 100.102.153.25/32 dev tailscale0
ip -6 addr add fd7a:115c:a1e0::9b39:9919/128 dev tailscale0 nodad
ip addr add 198.18.0.1/16 dev mihomo
ip -6 addr add fdfe:dcba:9876::1/126 dev mihomo nodad
ip route add default via 192.0.2.1 dev uplink
ip -6 route add default via 2001:db8:1::1 dev uplink
ip route add table 52 100.80.170.40/32 dev tailscale0
ip -6 route add table 52 fd7a:115c:a1e0::/48 dev tailscale0
ip route add table 2022 default dev mihomo
ip -6 route add table 2022 default dev mihomo
for family in -4 -6; do
  ip "$family" rule add priority 5210 fwmark 0x80000/0xff0000 table main
  ip "$family" rule add priority 5230 fwmark 0x80000/0xff0000 table default
  ip "$family" rule add priority 5250 fwmark 0x80000/0xff0000 unreachable
  ip "$family" rule add priority 5270 table 52
 done

assert_route() {
  local expected=$1
  shift
  local actual
  actual=$(ip "$@")
  if [[ $actual != *"$expected"* ]]; then
    printf 'Expected %s; got %s\n' "$expected" "$actual" >&2
    exit 1
  fi
}

# Simulate a failure halfway through installation and check rollback.
ip() {
  if [[ "$*" == '-6 rule add priority 5261 '* ]]; then
    return 1
  fi
  command ip "$@"
}
export -f ip
if bash "$ROUTING_SCRIPT" start 2>/dev/null; then
  echo 'Injected rule failure should fail installation' >&2
  exit 1
fi
unset -f ip
for family in -4 -6; do
  test -z "$(ip "$family" rule show pref 5260)"
  test -z "$(ip "$family" rule show pref 5261)"
done

bash "$ROUTING_SCRIPT" start
assert_route 'dev mihomo table 2022' -4 route get 100.80.170.40
assert_route 'dev mihomo table 2022' -6 route get fd7a:115c:a1e0::1234
assert_route 'dev tailscale0 table 52' -4 route get 100.80.170.40 from 100.102.153.25
assert_route 'dev tailscale0 table 52' -6 route get fd7a:115c:a1e0::1234 from fd7a:115c:a1e0::9b39:9919
assert_route 'dev uplink' -4 route get 1.1.1.1 mark 0x80000
assert_route 'dev uplink' -6 route get 2606:4700:4700::1111 mark 0x80000
assert_route 'local 100.102.153.25' -4 route get 100.102.153.25
assert_route 'dev uplink' -4 route get 192.0.2.1

if bash "$ROUTING_SCRIPT" start 2>/dev/null; then
  echo 'Duplicate/conflicting rule installation should fail' >&2
  exit 1
fi
assert_route 'dev mihomo table 2022' -4 route get 100.80.170.40

# An unavailable TUN must not blackhole the system Tailnet identity.
ip route flush table 2022
ip -6 route flush table 2022
assert_route 'dev tailscale0 table 52' -4 route get 100.80.170.40
assert_route 'dev tailscale0 table 52' -6 route get fd7a:115c:a1e0::1234
bash "$ROUTING_SCRIPT" stop
bash "$ROUTING_SCRIPT" stop
for family in -4 -6; do
  test -z "$(ip "$family" rule show pref 5260)"
  test -z "$(ip "$family" rule show pref 5261)"
 done
printf 'PASS: IPv4/IPv6 Tailnet outbounds, inbound replies, transport bypass, local access, conflict detection, fallback and cleanup\n'
TEST
