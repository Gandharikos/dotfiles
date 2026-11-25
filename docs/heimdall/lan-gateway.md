# Heimdall: full-LAN IPv4 gateway

## Rollout status

The user approved promoting the gateway beyond the two-client pilot on 2026-11-24. The prepared
scope is the existing `192.168.8.0/24` LAN on `enp2s0`, not guest networks or other VLANs. The
full-LAN admission was first installed as **generation 20**, at 23:21:18 UTC on 2026-11-24:

`/nix/store/wjhgy3r5xslxh9jska41gf8vlfvdf0i8-nixos-system-heimdall-26.11.20261111.d4f25a3`.

**The current retained system is generation 24**, with expanded
[AdGuard Home filtering](adguardhome.md), its reusable module extraction and the proxy panel
readiness fix and the scoped AdGuard LAN-readiness gate, without changing DHCP or gateway admission.
Eir/ymir DNS and web checks passed. Generation 20 remains the full-LAN rollback baseline without
filtering.

Flint settings have not been changed by the agent. The user subsequently confirmed that the iPhone
worked after reconnecting. Read-only checks on ymir independently found DHCP gateway and IPv4 DNS
`192.168.8.2` on `.106`. Initial fresh IPv6 solicitations still received a Flint RA (lifetime 1800),
so ymir's proxy shutdown was deferred. After the user confirmed disabling IPv6 and supplied an
off-state screenshot, ymir had no physical IPv6 default route or IPv6 DNS; three fresh solicitations
received no RA. Generation 661 then disabled ymir's local proxy, with Google/Baidu/WebUI and native
SSH/Rex checks passing through the new topology. Other clients' stale routes/leases remain to be
inventoried; these checks do **not** establish complete migration of every LAN client.

The original pre-cutover screenshots showed DHCP enabled, pool `192.168.8.100`–`192.168.8.249`,
lease 720 minutes, empty optional gateway/DNS fields, and Native IPv6 enabled. The later screenshot
shows IPv6 disabled; client runtime evidence above, rather than screenshots alone, gates activation.

## Client inventory — 2026-11-25

Read-only follow-up after generation 24 and eir's user-applied Darwin switch completed around
`2026-11-25T19:18:19Z`. No lease renewal, interface change, proxy toggle or reboot was performed.

| Client | Observed active IPv4 path                                                  | Gateway / DNS                                                   | Physical IPv6 evidence                                          |
| ------ | -------------------------------------------------------------------------- | --------------------------------------------------------------- | --------------------------------------------------------------- |
| eir    | Wi-Fi `en0`, manual `.116/24`                                              | `.2` / `.2`                                                     | Wi-Fi IPv6 off; no route to public IPv6 probe address           |
| ymir   | Wi-Fi `wlan0`, DHCP `.106/24`                                              | `.2` / `.2`                                                     | No physical default route or IPv6 DNS                           |
| tyr    | Ethernet `en0`, DHCP `.164/24`; Wi-Fi `en1`, manual `.161/24`, also active | Selected Ethernet route `.2`; DHCP router/DNS `.2`, server `.1` | Ethernet link-local only; no route to public IPv6 probe address |

Both Macs show scoped `utun` IPv6 defaults; those entries alone are not evidence of usable public
IPv6 or physical bypass. A route lookup for `2606:4700:4700::1111` failed on both. Eir's general
resolvers use `.2`; its separate `ts.net` resolver uses `100.100.100.100`, not a general public-DNS
override. Eir's HTTP/HTTPS/SOCKS/PAC flags are off. Ymir has no loaded sing-box/Mihomo/dae system
service or `sb-tun` interface. This does not rule out per-application DNS/proxies or every VPN path.

All three clients passed direct `.2:53` UDP/TCP checks for ads/porn/fakenews/gambling A/AAAA
blocking, Google/Facebook Fake-IP, Baidu real-IP and native Tailnet answers. Tyr additionally passed
the same checks addressed to external `1.1.1.1:53`, exercising routed DNS interception from its DHCP
Ethernet path. Tyr and ymir returned Google 204 and Baidu 200 with curl proxy use disabled; eir
passed those HTTPS probes immediately before this inventory during its startup-configuration
verification.

Tyr's simultaneous interfaces are recorded, not diagnosed as a fault or automatically disabled. Eir
`.116` and tyr Wi-Fi `.161` fall inside the last documented DHCP pool: verify matching Flint
reservations/exclusions before claiming address-conflict prevention. This snapshot does not prove
all-client migration, absence of stale leases elsewhere, gameplay/login/payment compatibility,
filter false-positive acceptance, off-home laptop operation or eir's fresh-boot execution.

## Ownership

- Flint (`192.168.8.1`) remains the sole DHCP server and upstream router. Heimdall remains static at
  `192.168.8.2/24`, outside the DHCP pool, with its own default route through Flint.
- Heimdall admits UDP/TCP DNS to `.2:53` and IPv4 proxy forwarding from the entire LAN prefix on
  `enp2s0`. Admission is no longer restricted to eir/tyr MAC/IP pairs. Only loopback is trusted; no
  public controller, guest-subnet admission, second DHCP server or general LAN masquerading is
  added.
- Since generation 21, AdGuard owns `.2:53` and forwards allowed queries to sing-box
  `127.0.0.1:1053`. The scoped `ip heimdall-dns` NAT chain redirects LAN port-53 traffic passing
  through Heimdall to this listener. It does not capture same-L2 DNS, encrypted DNS, host bootstrap
  or native exit DNS.
- The early forwarding guard drops LAN-source packets whose output is not `sb-tun`, even for
  established connections. Physical-interface IPv6 forwarding is rejected. IPv4 ICMP redirects are
  disabled globally, by default, and on `enp2s0`: clients must not learn a shortcut to Flint when
  the proxy path disappears. This is fail-closed, not automatic direct fallback.
- Priority 5100 sends LAN-source IPv4 Tailnet destinations through table 2023 and the embedded
  sing-box identity. Native host management and ordinary Tailscale exit routing remain separate.
- The legacy names `heimdall-pilot` and `heimdall-pilot-tailnet.service` are retained for lifecycle
  continuity; they now describe subnet-wide rules. Encrypted game policy and selectors are
  unchanged.

## Ordered cutover

1. Arm an independent rollback to the actual running generation, deploy the server admission change,
   verify CIDR-scoped DNS/forwarding and Tailnet routing, absence of the old per-client rules, the
   early guard and redirect sysctls, native exit routing, LAN HTTPS/DNS, and authenticated WebUI.
2. Retain the working full-LAN server and cancel its deployment timer **before** changing DHCP. This
   avoids a timer returning to the two-client whitelist after new clients receive `.2` leases.
3. In Flint's **DHCP Server** page, leave DHCP enabled and retain the pool/reservations/720-minute
   lease. Set Gateway to `192.168.8.2`, DNS Server 1 to `192.168.8.2`, and leave DNS Server 2 empty.
   Do not change Flint's own WAN/default gateway or upstream DNS. Its resolver must still provide
   real addresses for Heimdall's ordinary Tailscale exit; pointing it back to Heimdall would break
   that separation. Keep the saved original settings available for rollback.
4. Disable IPv6 in the displayed Flint IPv6 page for this IPv4-only rollout. The user approved this
   plan after reviewing the screenshots. Native IPv6 would otherwise bypass the new IPv4 gateway.
   This may interrupt existing IPv6 connections; it is not an assertion that proxy software cannot
   support IPv6. A later dual-stack deployment needs its own routing/RA/DNS design.
5. Reconnect or renew DHCP on clients and verify the actual address, default gateway and resolver.
   Existing leases and IPv6 router advertisements may remain cached. Verify that a public IPv6
   default route is no longer usable before claiming complete gateway ownership. Static addresses,
   VPN clients, application proxies and encrypted/custom DNS are separate exceptions.
6. Verify at least one formerly non-admitted client using fresh DNS and new connections. Do not
   describe DHCP clients as migrated until that has been observed. At initial cutover eir/tyr used
   manual `.2` settings and did not prove DHCP rollout by themselves; ymir and the later tyr
   Ethernet observation above provide separately observed DHCP paths.

## Server deployment evidence

- Default regressions and the remote toplevel build passed. An independent eight-minute rollback to
  generation 19 protected test activation. Activation succeeded without failed units.
- Live rules admit DNS and TUN forwarding for `192.168.8.0/24`, with no per-client MAC gate.
  Priority 5100 now matches the subnet; old priority 5101 is absent. Table 2023 remains
  sing-box-owned.
- Kernel lookups using formerly non-admitted source `192.168.8.200` selected the proxy TUN for
  public IPv4 and table 2023 for Tailnet IPv4. These are FIB checks, not a claim that a real `.200`
  client connected or that DHCP was changed. Native exit-source lookups still selected Flint
  directly.
- The early guard covers the whole LAN prefix and rejects physical-interface IPv6 forwarding.
  All/default/physical-interface IPv4 send-redirect settings read zero; physical IPv6 forwarding
  remained zero. No production proxy-stop fault injection or reboot was performed in this switch.
- Eir's existing LAN connection passed UDP/TCP DNS, Google 204, Baidu 200 and WebUI 200. The
  generated private proxy JSON and Game/Proxy selections exactly matched their pre-switch snapshots.
- Native tailscaled's PID did not change, and its private resolver remained Flint. Permanent
  retention did not cause another proxy/daemon restart. Running and boot-default closures match; the
  rollback timer was cancelled before instructing the user to change DHCP. The temporary private
  proxy-config comparison copy was removed.

Records: `/private/tmp/heimdall-full-lan/` on eir and `/run/heimdall-full-lan-deploy/` on Heimdall.
The user's iPhone reconnect report and ymir's DHCP state subsequently supplied client-side IPv4
evidence. After the user confirmed IPv6 disabled, ymir's physical IPv6 default/DNS were absent and
local-proxy-free HTTPS checks passed. Other clients still need stale-state checks; see
[ymir migration](../proxy/ymir-sing-box.md).

## Recovery

Before DHCP changes, the independent server rollback may safely return to generation 19. After
clients receive new leases, restore Flint's saved DHCP options first if necessary, while keeping
Heimdall's full-LAN admission running for clients that still retain `.2`. Renew/reconfigure those
clients before rolling the server back to a two-client whitelist. A DHCP rollback does not recall
already issued leases. Direct Flint access does not provide subscription-proxy routing.

Flint's management page remains at `http://192.168.8.1/`. No trusted SSH host key was available to
the agent, so it did not bypass host verification or alter router settings through SSH. Router UI
changes require user confirmation; no passwords belong in chat or command arguments.
