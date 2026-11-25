# Heimdall: ordinary native Tailscale exit

## Status

The user requested shelving the forced sing-box exit experiment on 2026-11-24. The declaration now
keeps native Heimdall as an ordinary Internet exit, independent of the LAN proxy gateway. This was
first installed and retained as **generation 19**, at 22:54:32 UTC on 2026-11-24, after explicit
deployment approval:

`/nix/store/187dx07s94xx3l9i082nkn9zcwhdl047-nixos-system-heimdall-26.11.20261111.d4f25a3`.

**The current system is generation 22**, retaining this ordinary exit, generation 20's full-LAN
admission and [AdGuard Home filtering](adguardhome.md) for host/LAN DNS. Native ExitDNS is unchanged
and does not use the Fake-IP/filtering path; see [full-LAN cutover](lan-gateway.md). Once DHCP
clients migrate, do not restore a two-client generation without coordinating client/lease recovery.

Generation 18 (generation 16's closure) was the rollback baseline for the initial exit switch:
`/nix/store/jsmk7lr6pgd6hm3my703x7j1chip8xvx-nixos-system-heimdall-26.11.20261111.d4f25a3`.

The experimental module, routing fixture, assertions and detailed diagnostic history are preserved
in stash `a360cfe9be1cac679930611b1b4095de1e8bf15b`, labeled
`archive/heimdall-singbox-exit-20261124`. A pre-change file backup also exists at
`/private/tmp/heimdall-exit-stash.f6Ey63Js/before`. Applying the stash is not a deployment; review
conflicts and lifecycle cleanup before reintroducing the experiment.

## Deployed ownership

- Native `heimdall` continues advertising IPv4/IPv6 exit capability, with no upstream exit selected
  and no LAN subnet advertised. Do not select or re-enroll the separate `heimdall-singbox` identity.
- Native Tailscale owns forwarding authentication, table 52 and SNAT. Ordinary IPv4 exit payloads
  use the main route through Flint (`192.168.8.1`), not proxy selectors or table 2024. The existing
  sing-box interface exclusion bypasses interception for packets arriving on `tailscale0`.
- The NixOS forwarding filter admits Tailnet IPv4 sources to public destinations through `enp2s0`.
  It does not trust the entire Tailnet interface or open private LAN/subnet/peer transit.
- `tailscaled` alone gets a read-only service-local `/etc/resolv.conf` pointing to Flint. Its
  ExitDNS responder must return real addresses, not sing-box Fake-IP answers. Since generation 21,
  host/LAN DNS uses AdGuard before sing-box; the native exit resolver remains outside that path.
- Generation 20's LAN admission covers `192.168.8.0/24`; see the separate LAN gateway guide. The
  early guard, table 2023, encrypted game policy, selectors, WebUI and separate identities remain
  independently managed. This exit configuration does not change DHCP or client configuration.
- The physical uplink still has no IPv6 default route. Advertising exit capability is not evidence
  of working IPv6 Internet access. Physical LAN IPv6 forwarding remains disabled.

This is a direct home-ISP exit, **not a subscription-proxy exit**. Foreign-site access is subject to
the home connection's restrictions. Tailnet relay/connectivity problems are not solved merely by
removing proxy forwarding.

## Deployment evidence

- Default regressions and the remote toplevel build passed. An independent eight-minute rollback
  timer was armed before test activation. The user authorized restarting sing-box and tailscaled.
- Initial activation returned a failure because the WebUI oneshot raced native daemon readiness:
  `tailscale serve` reported `unexpected state: NoState`. Once tailscaled reported Running, only
  `sing-box-tailnet-webui.service` was restarted. It succeeded; no failed units remained. This
  readiness race is not a cold-boot acceptance result and has not been fixed in the shared unit.
- Priorities 5102/5103, table-2024 routes and the `heimdall-exit` nftables table were removed. The
  table-2023 pilot and both LAN admissions remained. An actual kernel route lookup for a public
  destination from eir's Tailnet source, incoming on `tailscale0`, selected Flint via `enp2s0`.
  Native Tailscale forwarding-mark/SNAT rules and scoped NixOS acceptance were present.
- The daemon mount namespace reads `nameserver 192.168.8.1`; the host still reads `127.0.0.53`. Eir
  queried the authenticated-by-Tailnet PeerAPI ExitDNS endpoint: Baidu A and Google A/AAAA responses
  were successful and outside the Fake-IP ranges. This verifies ExitDNS, not full exit forwarding or
  usable IPv6 Internet access.
- The generated private sing-box JSON was identical to the pre-switch snapshot. Game/Proxy selector
  choices and native Tailscale ID/key/addresses were unchanged. Only the two exit defaults remained
  advertised, with no selected upstream exit or LAN route advertisement.
- Physical-uplink Baidu returned 200. Eir's existing LAN path returned Google 204, Baidu 200 and
  WebUI 200; the unauthenticated controller API returned 401. These are control checks, not cellular
  exit end-to-end acceptance. No client exit selection was changed during deployment.
- Permanent retention did not restart sing-box or tailscaled a second time (PIDs unchanged). Running
  and boot-default closures match generation 19; the rollback timer was cancelled and the temporary
  private proxy-config comparison copy removed.

Records: `/private/tmp/heimdall-exit-stash.f6Ey63Js/{build,activate,dry-activate}.log` on eir and
`/run/heimdall-native-exit-deploy/` on Heimdall. Remote exit TCP/UDP, cellular performance and
reboot acceptance remain outstanding. Clients that cached old Fake-IP answers may need DNS-cache
refresh before using the ordinary exit.

## Activation gates

Use the network ownership/rollback procedure in [networking](../networking.md). Before activation:

1. Build the candidate and inspect the service restart plan. Obtain approval before any sing-box
   restart during gameplay; a helper/source change can trigger a restart even if policy is
   unchanged.
2. Arm an independent rollback to the actual running closure. Preserve native SSH/LAN recovery.
3. On test activation, stop the removed `heimdall-exit-route` service and verify that networkd
   removes only priorities 5102/5103 and table-2024 unreachable defaults. Remove no unrelated policy
   rules.
4. Verify removal of the `heimdall-exit` nftables table and preservation of the two-client pilot.
   Confirm new source-scoped forwarding acceptance and native Tailscale SNAT.
5. Check the daemon's private resolver view, real-IP ExitDNS answers and unchanged host/LAN DNS. The
   resolver namespace change requires a native tailscaled restart, not identity replacement.
6. Verify ordinary IPv4 exit routing, domestic HTTPS, native management, WebUI and LAN proxy/game
   policy. Retain only after these checks; then cancel the rollback timer.

Do not reuse the earlier eir hotspot trial as exit acceptance. Its physical uplink passed Baidu
HTTPS, but selecting the exit produced a missing local route. Eir's open-source macOS tailscaled may
be affected by [upstream #21395](https://github.com/tailscale/tailscale/issues/21395); the exact
cause was not established. Its original network location, static home address/DNS and empty exit
selection were restored. Phone TestFlight testing was deferred at the user's request.
