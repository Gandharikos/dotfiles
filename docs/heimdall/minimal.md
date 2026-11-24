# Heimdall: minimal base and sing-box bring-up

The host retains the verified N150 hardware, Disko ext4/EFI layout (no disk swap), systemd-boot,
zram, the johnson user, shared SSH settings, and networkd management at `192.168.8.2/24`. Its
default route points to Flint `192.168.8.1`. The sing-box host proxy is now enabled, with system DNS
using its loopback listener. Bounded IPv4 LAN gateway tests passed as recorded below; forwarding is
not permanently enabled. NetworkManager, IPv4/IPv6 forwarding and NAT remain disabled. Tailscale is
enabled as a plain client with autoconnect, using the shared SOPS-managed auth key from
`secrets/services/tailscale.yaml` when enrollment is needed. It does not accept DNS or subnet
routes. It inherits the shared `--ssh` flag, enabling Tailscale SSH. No subnet routes are declared;
previously saved advertisements are not explicitly cleared. Heimdall explicitly sets `exitNode = ""`
to clear any saved exit-node selection and use its own default route. The shared default remains
`null` (unmanaged); other hosts are unchanged. OpenSSH inherits the global ports 22 and 2222;
Tailnet traffic still passes the host firewall rather than gaining blanket interface trust. With
Tailscale SSH enabled, use port 2222 for ordinary OpenSSH through the Tailnet address.

Dedicated `.sops.yaml` rules grant Heimdall access to `secrets/services/tailscale.yaml` and
`secrets/services/proxy.yml`, not other shared service secrets. Recipients were updated without
changing the encrypted payloads, and decryption was verified on Heimdall. Preserve the on-disk
Tailscale identity.

No DHCP server, OliveTin panel, gateway health service or gateway release machinery is imported.
Keep the SSH key and existing Tailscale identity/state on the machine.

`hosts/heimdall/hardware-configuration.nix` is generated on the physical host using
`nixos-generate-config --show-hardware-config --no-filesystems`, then formatted with nixfmt.
Filesystem declarations remain owned by Disko. The verified disk path and management NIC MAC are
specified directly in `config.nix`; there is no `dot.hardware.heimdall` option layer or confirmation
flag. Generating this file reads hardware only; it does not install or activate a system.

The opt-in `modules/nixos/profiles/router/default.nix` profile provides a lightweight environment
for router hardware. Heimdall enables it with `dot.profiles.router.enable = true`: powersave CPU
governor, no automatic powertop tuning, one concurrent Nix build with two cores, empty NIX_PATH and
only the pinned nixpkgs registry entry. It defaults to minimal/headless operation with zram and
network diagnostic tools, with Plymouth, application hosting, persistence and YubiKey support off.

The network baseline uses networkd rather than NetworkManager, with nftables enabled and forwarded
traffic filtered. It trusts only `lo`, removing inherited VPN/LAN/container trust while preserving
local DNS/proxy connections. It removes public/fallback DNS so the host owns resolver selection.
mDNS, forwarding, NAT, proxy and VPN are off by default; DHCP servers are not enabled. Ordinary host
settings can override the scalar defaults, including NetworkManager (the profile uses priority 900
to beat the shared priority-1000 default). Empty global nameservers and loopback-only interface
trust remain forced policies; link-specific DNS is still configurable.

Other hosts are unchanged unless they enable the profile. Disk layout, bootloader, Secure Boot,
interface matching, link settings, IP family selection, addresses, SSH, Tailscale and user
configuration remain host-owned. In particular, Heimdall's IPv4-only management link is not imposed
on other router hosts.

The host-scoped maintenance module retains fixes for the four-core CPU's kernel parameters and an
unsupported systemd service setting. The shared Disko helper's optional disk-swap setting is
retained because it describes the installed disk layout; other callers keep their existing defaults.

## Deployment and validation — 2026-11-24

The minimal configuration was built on Heimdall, activated with `test`, then switched permanently at
2026-11-23 23:30 UTC (2026-11-24 locally). Generation 7 was the initial minimal system profile; the
observations below are historical, superseded by the bring-up notes:

`/nix/store/hs4cly5acsm4b07gzkk7nsf3rmk7d5xz-nixos-system-heimdall-26.11.20261111.d4f25a3`

The frozen deployment source is `/nix/store/vzbphbvjjn4p0fx39m021f2yl9z130vy-source`.

- Fresh, host-key-pinned ordinary SSH connections through `100.76.84.51:2222` passed after test,
  switch and removal of the temporary SSH socket override. Native sockets listen on 22 and 2222.
- Tailscale is running with the same node ID and IP. Tailscale SSH is enabled; DNS/routes are not
  accepted, no subnet advertisements or exit node are selected. Autoconnect and SOPS completed
  successfully; the secret is root-owned mode 0400.
- DNS remains on `192.168.8.1`; direct HTTPS to `cache.nixos.org` passed certificate validation.
  IPv4/IPv6 forwarding are zero. There are no failed systemd units.
- Old DHCP, proxy, panel and release services are inactive and absent from the new configuration.
  There is no UDP/67 listener or `arm-front` link. Runtime masks were retained for old gateway
  services. Gateway data on disk was not deleted.
- The test had an eight-minute automatic rollback timer, with old gateway services masked so a
  rollback would not restart them. The timer was cancelled after the successful permanent switch.
- Direct LAN SSH was unreachable at this stage. Later investigation identified Flint Main Network's
  enabled AP Isolation; disabling it restored LAN SSH, as recorded below.

No reboot, reinstall or repartition was performed. Cold-boot behavior is not verified. Older boot
entries still contain the abandoned gateway; do not select them as a routine rollback without
accounting for their services. `deployable = false` remains intentional for automated target
selection. Never rerun Disko or an installer to apply ordinary configuration changes.

## Sing-box host-proxy bring-up — 2026-11-24

Flint PORT 02 was already LAN/main at 2.5 Gbit/s. The user disabled Main Network AP Isolation;
host-key-pinned LAN SSH to `192.168.8.2` then succeeded. The UI also showed DHCP disabled. The user
was asked to restore Flint DHCP because Heimdall has no DHCP server; restoration is not yet
verified.

A separate router-profile defect had removed loopback firewall trust. Restoring only `lo` fixed
local DNS and TCP connections without trusting LAN/Tailnet interfaces. The repair was built, tested
with LAN and Tailnet SSH plus direct HTTPS, and switched as generation 8 at 01:39 UTC:

`/nix/store/y58ax74nawb7mnlklhsxfynhxkm74dil-nixos-system-heimdall-26.11.20261111.d4f25a3`

This is the preferred minimal rollback baseline. A temporary loopback-only SSH download tunnel was
removed after the repair restored normal direct downloads. A regression assertion now requires
loopback-only trust for router-profile hosts.

`hosts/heimdall/sing-box.nix` is imported and reuses ymir's shared profile and encrypted node seed.
The first attempt blocked while downloading remote rule sets before opening DNS/proxy listeners, and
was returned to generation 8. The replacement uses `profile.singBox.ruleSetFiles` to preload both CN
rule sets from a pinned upstream revision and hashes during the build. Rule ordering and selectors
are unchanged; these two snapshots now require deliberate updates rather than runtime refresh. Other
hosts retain remote rule-set behavior.

Generation 9 was switched at 01:57 UTC, with its test rollback timer cancelled after verification:

`/nix/store/yl1r1qh25d5a11lbb5bkxdshyyxwpwfy-nixos-system-heimdall-26.11.20261111.d4f25a3`

Verified: 32 Trojan nodes rendered; both CN rule sets are local; mixed-proxy and host-TUN requests
to Google's generate_204 returned 204; domestic HTTPS returned 200; LAN and Tailnet SSH still work.
DNS, mixed proxy and controller listen only on loopback ports 1053, 7890 and 9090. IPv4/IPv6
forwarding remain zero, with no DHCP listener. The optional online subscription refresh failed on
both startup and retry; the valid SOPS seed remains in use. A subsequent successful system switch
cleared failed-unit state, but this does not prove subscription refresh works.

Kernel IPv6 is enabled for the shared dual-stack TUN, retaining the management link's RA policy. The
new embedded identity is `heimdall-singbox`, with fresh host-local state; no ymir identity was
copied. The user completed authorization using the private login link in the Rex
`heimdall-tailnet-login` tab. Explicit mixed-proxy HTTPS probes then reached `eir-rex`, `ymir-rex`
and `tyr-rex` with valid certificates and HTTP 404 at `/`. The first short ymir probe timed out; a
subsequent longer probe succeeded. This verifies the embedded transport to the Rex HTTPS servers,
not, at that stage, an authenticated Rex session or LAN transparent routing. The subsequent bounded
IPv4 pilot below adds those checks. Remote WebUI exposure stays disabled. Do not activate dae or
restore the archived gateway machinery.

### First bounded LAN forwarding probe

Tyr was selected as the pilot: Wi-Fi `en1`, `192.168.8.161`, DHCP router/server `192.168.8.1`, with
Surge TUN and system proxies still enabled. The test added only a temporary host route for `1.1.1.1`
via Heimdall. Curl explicitly bypassed HTTP proxies, bound to `en1`, and used a fixed address with
normal TLS verification for `https://one.one.one.one/cdn-cgi/trace`.

Heimdall temporarily enabled IPv4 forwarding and accepted only tyr-to-`1.1.1.1:443` traffic from
`enp2s0` to `sb-tun`. The request returned HTTP 200 with certificate verification success, and the
scoped forwarding rule recorded the new connection. This verifies a real LAN-client TCP flow through
the sing-box TUN, not merely an explicit proxy request.

The client had a 90-second system launchd guard and immediate exit cleanup; the server had a
three-minute systemd guard. The initial launchctl-submit guard could not be verified and aborted
before adding a route; the successful run used explicit system-domain bootstrap. The host route was
removed, its lookup returned to Surge's `utun5`, the server rule was removed, and forwarding was
restored to zero with declared sysctls reapplied. Sing-box and system Tailscale remain active.
Default client routing/DNS, Surge settings and Flint DHCP were not changed. This does not yet
validate proxy-disabled operation, DNS, UDP, IPv6 or an actual Rex session through the LAN gateway.

### Proxy-disabled IPv4 pilot — passed and restored

The next bounded test temporarily disabled tyr's Surge enhanced mode and HTTP/HTTPS/SOCKS system
proxy settings, disabled Wi-Fi IPv6 to prevent bypass, and set IPv4 gateway/DNS to `192.168.8.2`.
Surge's system-proxy CLI operation failed before cutover; native `networksetup` was used instead,
without changing proxy endpoints, profiles or selectors. A three-minute system-domain launchd guard
and immediate exit cleanup protected tyr; a six-minute systemd guard protected Heimdall.

Heimdall temporarily accepted only tyr's IPv4 forwarding into `sb-tun` and TCP/UDP DNS requests to
its additional resolved listener at `192.168.8.2:53`. A source/interface-scoped priority-5100 rule
sent forwarded tyr traffic for `100.64.0.0/10` into a dedicated table 2023 route via `sb-tun`. This
let forwarded Tailnet traffic use the embedded endpoint without changing the host's native Tailscale
table 52 or its local management path. No NAT or DHCP server was introduced.

The first cutover exposed a DNS ownership conflict: native Tailscale's `CorpDNS=true` left the
primary system resolver at `100.100.100.100` despite the Wi-Fi DNS setting. Direct UDP/TCP queries
to Heimdall passed, but normal applications bypassed that resolver; Baidu HTTPS failed against a
different address. Temporarily setting only `--accept-dns=false` made Heimdall the primary resolver
and fixed that failure. Other native Tailscale preferences and identity were preserved.

With Surge interception off, IPv6 disabled and the default route through Heimdall, verified:

- UDP and TCP DNS through Heimdall; normal Google resolution used its `198.18.0.2` fake address.
- Google generate_204 returned 204; Baidu and Bilibili HTTPS returned 200, with TLS verification.
- A temporary host route for the ymir Rex peer explicitly exercised LAN-to-embedded-Tailnet
  forwarding. Its HTTPS root returned the expected 404 with valid TLS.
- A new eir-to-tyr authenticated Rex API connection and remote command succeeded during cutover;
  that command independently confirmed Surge off, system proxy flags zero and gateway/DNS `.2`.
- Tyr's authenticated `rex ... whoami` against the explicit `https://ymir-rex.tail2cfd9e.ts.net`
  endpoint returned account `johnson` and source node `heimdall-singbox`. The local alias `ymir` had
  pointed to the wrong system identity. Earlier explicit-endpoint attempts also timed out, including
  on the original network; the final check succeeded after a 35-second observation interval.
  Long-term stability is not inferred from this.

Tyr was restored to DHCP router `.1`, DHCP-provided DNS, automatic IPv6, `CorpDNS=true`, Surge
interception and all three system proxy flags enabled. The temporary peer route and launchd guard
were removed and the root test shell exited. Heimdall's pilot rules, table-2023 route, priority-5100
rule and extra DNS listener were removed; forwarding is again zero, and normal Tailnet SSH passed.
The system remains generation 9's host-proxy configuration. Eir and Flint DHCP were not changed.

This is bounded IPv4 web/DNS and Rex control validation, not permanent client rollout, browser/UI
acceptance, IPv6 gateway support, general UDP/QUIC proxy validation, cold boot or failure recovery
under ongoing client traffic. The online subscription-refresh limitation above also remains.

All removed Heimdall work remains in Git stash `1290daee42dd7e15b09b9e56cbbd23aa7bf4ffce` (including
its untracked-file parent). Do not pop the whole stash over these minimal files unless intentionally
restoring the gateway implementation.
