#!/usr/bin/env bash
set -euo pipefail

# Model system Tailscale and proxy route priority in a disposable namespace.
# This checks kernel policy lookup, not authentication or a live proxy core.
unshare --user --map-root-user --net bash <<'TEST'
set -euo pipefail
ip link set lo up
for device in uplink tailscale0 proxy-tun; do
  ip link add "$device" type dummy
  ip link set "$device" up
done
ip addr add 192.0.2.2/24 dev uplink
ip -6 addr add 2001:db8:1::2/64 dev uplink nodad
ip addr add 100.102.153.25/32 dev tailscale0
ip -6 addr add fd7a:115c:a1e0::9b39:9919/128 dev tailscale0 nodad
ip addr add 172.19.0.1/30 dev proxy-tun
ip -6 addr add fdfe:dcba:9876::1/126 dev proxy-tun nodad
ip route add default via 192.0.2.1 dev uplink
ip -6 route add default via 2001:db8:1::1 dev uplink
ip route add table 52 100.80.170.40/32 dev tailscale0
ip -6 route add table 52 fd7a:115c:a1e0::/48 dev tailscale0
ip route add table 2022 default dev proxy-tun
ip -6 route add table 2022 default dev proxy-tun
for family in -4 -6; do
  ip "$family" rule add priority 5210 fwmark 0x80000/0xff0000 table main
  ip "$family" rule add priority 5230 fwmark 0x80000/0xff0000 table default
  ip "$family" rule add priority 5250 fwmark 0x80000/0xff0000 unreachable
  ip "$family" rule add priority 5270 table 52
  ip "$family" rule add priority 9000 table main suppress_prefixlength 0
  ip "$family" rule add priority 9001 table 2022
done

assert_route() {
  local expected=$1 actual
  shift
  actual=$(ip "$@")
  if [[ $actual != *"$expected"* ]]; then
    printf 'Expected %s; got %s\n' "$expected" "$actual" >&2
    exit 1
  fi
}

assert_native_tailnet() {
  assert_route 'dev tailscale0 table 52' -4 route get 100.80.170.40
  assert_route 'dev tailscale0 table 52' -6 route get fd7a:115c:a1e0::1234
  assert_route 'dev tailscale0 table 52' -4 route get 100.80.170.40 from 100.102.153.25
  assert_route 'dev tailscale0 table 52' -6 route get fd7a:115c:a1e0::1234 from fd7a:115c:a1e0::9b39:9919
}

assert_native_tailnet
assert_route 'dev proxy-tun table 2022' -4 route get 1.1.1.1
assert_route 'dev proxy-tun table 2022' -6 route get 2606:4700:4700::1111
assert_route 'dev uplink' -4 route get 1.1.1.1 mark 0x80000
assert_route 'dev uplink' -6 route get 2606:4700:4700::1111 mark 0x80000
assert_route 'local 100.102.153.25' -4 route get 100.102.153.25
assert_route 'dev uplink' -4 route get 192.0.2.1

# Reproduce the retired override, then verify that its removal restores both families.
ip -4 rule add priority 5261 to 100.64.0.0/10 iif lo table 2022
ip -6 rule add priority 5261 to fd7a:115c:a1e0::/48 iif lo table 2022
assert_route 'dev proxy-tun table 2022' -4 route get 100.80.170.40
assert_route 'dev proxy-tun table 2022' -6 route get fd7a:115c:a1e0::1234
ip -4 rule del priority 5261 to 100.64.0.0/10 iif lo table 2022
ip -6 rule del priority 5261 to fd7a:115c:a1e0::/48 iif lo table 2022
assert_native_tailnet

ip route flush table 2022
ip -6 route flush table 2022
assert_native_tailnet
for family in -4 -6; do
  test -z "$(ip "$family" rule show pref 5260)"
  test -z "$(ip "$family" rule show pref 5261)"
done
printf 'PASS: native IPv4/IPv6 Tailnet, system replies, transport bypass, public TUN traffic, local access and proxy-table removal\n'
TEST
