# Heimdall: minimal base and sing-box bring-up

The host retains the verified N150 hardware, Disko ext4/EFI layout (no disk swap), systemd-boot,
zram, the johnson user, shared SSH settings, and networkd management at `192.168.8.2/24`. Its
default route points to Flint `192.168.8.1`. The sing-box host proxy is now enabled, with system DNS
using its loopback listener. **Generation 20 is installed and retained:** IPv4 gateway admission now
covers `192.168.8.0/24`, with early fail-closed forwarding and ICMP redirects disabled. The user
confirmed iPhone access after reconnecting; ymir obtained DHCP gateway/DNS `.2`. After the user
confirmed IPv6 disabled, ymir had no physical IPv6 default/DNS and passed HTTPS checks with its
local proxy disabled. Other clients' stale-state checks remain outstanding; see
[full-LAN cutover](lan-gateway.md). Generation 19's ordinary native Tailnet exit through Flint and
service-local real-IP DNS remain unchanged. The forced sing-box exit experiment is shelved in stash
`a360cfe9`. Game policy, selectors and WebUI are preserved; see [exit-node operation](exit-node.md).

Previously, generation 18 restored generation 16's configuration and encrypted raw-IP game
correction after the generation-17 experiment failed phone acceptance. The user confirmed working
gameplay. Cellular browsing worked slowly at one point but subsequently stalled again. Eir's guarded
hotspot trial passed basic Internet access but failed with the exit selected and a missing local
route; it returned safely to the home configuration. Separating off-LAN transport from client route
handling remains unresolved; the user deferred that investigation in favor of full-LAN rollout. See
[exit-node operation](exit-node.md) for evidence and remaining limits. The Tailnet-only controller
WebUI and encrypted manual game selector are retained. Tyr still uses the gateway; eir has completed
a guarded return from Flint with both Surge takeover modes disabled. This is not full-network
acceptance. NetworkManager and NixOS NAT remain disabled. IPv6 forwarding is enabled for the virtual
exit/TUN links but blocked on the physical LAN; the LAN gateway remains IPv4-only. Native Tailscale
now advertises exit routes with autoconnect, using the shared SOPS-managed auth key from
`secrets/services/tailscale.yaml` when enrollment is needed. It does not accept DNS or subnet
routes. It inherits the shared `--ssh` flag, enabling Tailscale SSH. Only the two exit defaults are
currently advertised; no LAN subnet route is declared. Heimdall explicitly sets `exitNode = ""` to
clear any saved exit-node selection and use its own default route. The shared default remains `null`
(unmanaged); other hosts are unchanged. OpenSSH inherits the global ports 22 and 2222; Tailnet
traffic still passes the host firewall rather than gaining blanket interface trust. With Tailscale
SSH enabled, use port 2222 for ordinary OpenSSH through the Tailnet address.

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

## Persistent IPv4 pilot server — generation 10

Generation 10 first enabled persistent forwarding and LAN DNS for tyr only: `192.168.8.161`,
observed Wi-Fi source MAC `22:33:65:a3:9e:de`. Both values must match for DNS and new forwarded
connections. Reserve that address for this MAC on Flint before making tyr's client settings
persistent; the hardware MAC shown by macOS is not necessarily its per-network private address. Keep
the private Wi-Fi address stable and do not change all clients' DHCP gateway.

The module enables forwarding in both the kernel and the management link's networkd settings, adds a
resolved listener on `.2:53`, and declares the pilot's priority-5100 policy rule in networkd so it
survives link reconfiguration. A routing service owns only the table-2023 route: it follows sing-box
startup, shutdown and restart, waits up to 30 seconds for the TUN address, and removes its exact
route when stopped. Native host Tailscale routing is unchanged. Switching away from sing-box
disables this host pilot module.

A separate nftables forward hook precedes the normal established-connection accept rule. It drops
pilot packets with a different MAC or an output interface other than `sb-tun`, preventing direct
fallback through Flint if the TUN disappears. This also intentionally does not enable routed access
to other private subnets through Flint. Local `192.168.8.0/24` peers remain directly reachable. No
NAT, DHCP server, IPv6 gateway, broad interface trust or public controller is added.

Default regressions passed, including the gateway assertions and the dae fixture with forwarding
disabled. The candidate system built successfully on Heimdall:
`/nix/store/vh3p5b7rcdw44ijnaj5fikmrqalil4m9-nixos-system-heimdall-26.11.20261111.d4f25a3`. The user
reported saving the Flint reservation for the pilot MAC and address. At 04:19 UTC on 2026-11-24, the
candidate was switched as generation 10 after guarded test activation. Fresh Tailnet SSH, host HTTPS
and UDP/TCP DNS queries from tyr passed; the DNS firewall counter verified the MAC/IP-scoped rule
was used. Restarting sing-box restored its companion routing service and table-2023 route;
`networkctl reload` retained the declared rule and route. This was not a networkd restart or
cold-boot test. The test rollback timer was cancelled after the permanent switch. Proxy-loss
forwarding behavior under live client traffic remains untested.

Generation 9 remains the host-proxy rollback baseline. The retained client trial below tests
ordinary native Tailscale/Rex paths without the earlier one-peer route used to demonstrate the
embedded endpoint. General UDP/QUIC and IPv6 are not yet accepted.

### Persistent client attempt — not retained

A guarded attempt set tyr's reserved `.161` address manually, with gateway/DNS `.2`, Wi-Fi IPv6 off,
native Tailscale DNS acceptance off, and Surge interception off. Web and UDP/TCP DNS probes passed.
Unlike the earlier embedded-endpoint demonstration, no peer host route was added: `100.64.0.0/10`
still used native Tailscale's `utun0`. The ymir Rex endpoint answered, but the Rex API welcome
handshake timed out. No KEEP confirmation was issued and the client script restored its original
configuration. This ordinary native path has not passed acceptance.

Restoration initially lost connectivity because DHCP availability had not been verified before
relying on DHCP rollback. The user then enabled Flint DHCP; tyr became reachable again at `.161`.
Fresh authenticated Rex access confirmed recovery. Verified restored state: DHCP router `.1`,
DHCP-provided DNS, automatic IPv6, `CorpDNS=true`, HTTP/HTTPS/SOCKS proxy flags enabled and Surge
enhanced mode on. The root test shell was exited. Before another cutover, verify the DHCP recovery
path rather than inferring availability from a saved reservation or old lease. DHCP recovery does
not explain away the preceding native Rex handshake failure; investigate that separately. The server
remained generation 10; that attempt did not retain tyr on the gateway.

### Follow-up client trial — settings retained

After DHCP recovery, a baseline native Tailscale ping reached ymir-rex directly over LAN and both
HTTPS and the authenticated Rex API passed. The next guarded attempt added bounded idle-sleep
prevention, native peer path probes, three fresh Rex API checks and a static `.161`/gateway `.1`
fallback if DHCP restoration failed. Surge's reported system-proxy state disagreed with macOS;
preflight therefore checked the three actual network-service proxy flags rather than that label.

This attempt passed DNS over UDP/TCP, Google (204), Baidu (200) and Bilibili (200), with TLS
verification enabled. Native Tailscale initially used DERP(nue), then reached ymir-rex at the LAN
endpoint in subsequent probes. All three Rex API checks returned the `tyr` principal. Independent
eir-to-tyr Rex connections and a remote command verified the cutover while it was active; Heimdall's
scoped forwarding counter increased. No peer route was installed. These observations suggest a
path-convergence issue worth tracking, not proof that the earlier timeout has been fully explained.

KEEP was confirmed only after those checks. The launchd rollback guard was removed and the root
shell exited. Record: `/private/tmp/heimdall-tyr-persistent.zIuJ1a5N`. Retained client settings:

- Wi-Fi `en1`: manual `192.168.8.161/24`, router and DNS `192.168.8.2`, IPv6 off;
- Surge enhanced mode off and HTTP/HTTPS/SOCKS proxy flags off;
- native Tailscale remains active, with `CorpDNS=false` and its ordinary routes intact;
- Flint keeps DHCP enabled, with the pilot's MAC reservation; other clients are unchanged.

`hosts/tyr/config.nix` now declares `acceptDns=false`. Evaluation confirms nix-darwin has no known
network services to rewrite the manually retained Wi-Fi settings. The DNS-only deployment below
replaced the installed boot helper with `--accept-dns=false`, without upgrading the workstation. No
reboot has been performed. Long-term stability, proxy failure under client traffic, general UDP/QUIC
and IPv6 remain separate gates.

#### DNS-only Darwin deployment — generation 600

A full current-checkout build succeeded as
`/nix/store/1sxics490r3jzwpxw8ya2k414xc4np7r-darwin-system-26.11.ff0e21a`, but review found
unrelated package/service changes relative to tyr. It was not activated. The current generation was
exactly reproduced from its retained source before preparing a narrower candidate:

- Previous baseline: `/nix/store/0rp82dnv2g12jzpms9gxnd6fsp9p0sd9-darwin-system-26.11.ff0e21a`.
- Retained source: `/nix/store/rm5sb5flj7rqqbcmn6hy317ml7qqngp5-source`.
- Running DNS-only system:
  `/nix/store/k14syi8cy3ys86vky884s29pqsvpjaw1-darwin-system-26.11.ff0e21a`.
- Candidate GC root on tyr: `/Users/johnson/.local/state/heimdall-dns-build.tjSu4swk/system`.

The candidate was built on tyr with the retained flake's `darwinConfigurations.tyr.extendModules`,
adding only `dot.networking.tailscale.acceptDns = false`. Closure diff showed no package-version
changes. System packages, `/etc`, applications, patches and fonts retain identical store targets;
LaunchAgents have identical contents. The only changed LaunchDaemon plist is
`org.nixos.tailscale-up`. Its generated program was compared byte-for-byte: the only change is
`--accept-dns=true` to `--accept-dns=false`, preserving the existing Tailscale package and flags.

Normal full activation would also run the baseline's Homebrew upgrade/cleanup and Home Manager
activation. Instead, guarded targeted activation installed only the generated helper plist and
updated the matching system-profile/current-system pointers, after rechecking those boundaries. The
full activation script was not run. The boot activation program was inspected; it restores the
current-system link from the system profile and sets up `/etc`, rather than reinstalling
LaunchDaemon plists.

The first attempt (generation 598) passed helper/web checks but made the current-system symlink
unreadable to ordinary users: unlike Linux, macOS enforces the symlink mode created under a private
umask. That attempt was explicitly rolled back (599), the link repaired, and deployment/rollback
scripts corrected to create the system link under umask 022. The second attempt was independently
verified and retained as generation 600, at 18:43:56 local time on 2026-11-24. Record:
`/private/tmp/tyr-dns-activate.fqmriacE`.

The new helper completed with exit status 0 and `CorpDNS=false`. Native tailscaled PID and node
identity were unchanged; Rex retained PID 1669 and its existing instance ID. Google (204), Baidu
(200), three fresh tyr-to-ymir authenticated Rex checks, fresh eir-to-tyr Rex and LAN SSH all
passed. The manual `.161`/gateway-DNS `.2`/IPv6-off client settings remained intact. The rollback
guard was removed after KEEP, and the root shell exited. No Homebrew upgrade, Home Manager
activation, Tailscale daemon restart, Rex restart or machine reboot was performed.

The current checkout carries the same DNS declaration, but the deployed generation intentionally
uses the retained baseline and is not a deployment of all intervening repository changes.

#### First reboot — network probes passed, startup acceptance incomplete

The user restarted tyr and completed local FileVault unlock/login. The boot timestamp changed from
1795288940 to 1795519547 (2026-11-24 19:25:47 local). Generation 600, the reserved manual IPv4
address, gateway/DNS `.2`, IPv6 off, disabled system proxy flags and `CorpDNS=false` survived. Surge
was not running. UDP/TCP DNS, ordinary Google/Baidu/Bilibili HTTPS and three fresh native
tyr-to-ymir Rex API checks passed without first issuing a special peer ping or installing a peer
route.

However, `org.nixos.tailscale-up` was in `spawn scheduled` with `EX_CONFIG` (78). Launchd's boot log
explicitly reported its store executable missing at startup, even though the file existed after
login. The retained runtime DNS preference is not proof the boot helper executed successfully.
`modules/darwin/networking/tailscale.nix` now starts this helper through the macOS `/bin/sh` and
`/bin/wait4path` for its executable, matching the mount-order protection used by native tailscaled.
This affects future Darwin autoconnect deployments; it does not modify Tailscale flags or Linux.

A scoped candidate built successfully on tyr, preserving generation 600's packages and changing only
the helper plist: `/nix/store/1ym5hf9sykkbd4vk6574xsh82h5s0np8-darwin-system-26.11.ff0e21a`. Its GC
root is `/Users/johnson/.local/state/heimdall-boot-wait.rq9Nn3ii/system`. Default regressions,
including startup-wrapper assertions, passed. The wrapper was subsequently retained as generation
603, as recorded below.

Inbound Rex also needs separate recovery: the Rex application was not running after login. The SSH
environment selected an older CLI, whose local server reported Tailnet disabled; opening the
installed `/Applications/Rex.app` then reported `needs_login`. The user was asked to complete the
Rex application's Tailnet login privately. No auth links, keys or tokens were copied or logged, and
native Tailscale was not logged out. The user subsequently completed that login; fresh authenticated
eir-to-tyr Rex access succeeded and the application reported `running` at the original
`tyr-rex.tail2cfd9e.ts.net` hostname (PID 2621). This first reboot is not full gateway/startup
acceptance.

#### Startup-wrapper activation — generation 603

The first guarded attempt (601) executed the helper successfully but immediately failed a native
Tailnet name lookup; it automatically restored generation 600's closure under profile
generation 602. Independent checks showed ymir-rex online and both gateway DNS and native MagicDNS
answering. The next attempt added bounded readiness probes (six attempts, three-second ping timeout
and five-second pauses), without changing routes or pinning the peer address.

Generation 603 was retained at 19:53:41 local time on 2026-11-24. Only the generated helper plist
and matching system-profile/current-system pointers were updated. The native daemon PID and node
identity remained unchanged. The helper exited successfully, `CorpDNS=false` remained set, web
checks passed, and three independent tyr-to-ymir Rex API calls plus fresh inbound Rex passed. Rex
retained PID 2621 and its instance ID. The rollback guard was removed after KEEP and the
administrator shell exited. Record: `/private/tmp/tyr-boot-wait.LeLDt2nb`.

The active closure is `/nix/store/1ym5hf9sykkbd4vk6574xsh82h5s0np8-darwin-system-26.11.ff0e21a`. A
further user-performed reboot tested the mount-order fix, as recorded below. Check networking and
the helper before invoking the older SSH-environment Rex CLI; open the installed Rex application
normally if it is not already running, rather than autostarting a different server with that old
CLI. Do not infer automatic Rex login/startup from network checks alone.

#### Second client reboot — scoped IPv4 recovery passed

The user restarted tyr again and completed local unlock/login. Boot timestamp 1795521734 confirms
the new boot at 2026-11-24 20:02:14 local. Generation 603 remained active and
`org.nixos.tailscale-up` completed automatically with exit status 0, rather than the earlier spawn
failure. Manual `.161/24`, gateway/DNS `.2`, IPv6 off, disabled HTTP/HTTPS/SOCKS proxy flags and
`CorpDNS=false` all survived. The process check found the Rex application and no Surge application.

Without changing network settings or issuing a preparatory peer ping, UDP/TCP DNS and ordinary
Google (204), Baidu (200) and Bilibili (200) HTTPS probes passed with TLS verification enabled. The
default IPv4 route used `en1` through `.2`. The already running Rex server reported the original
`tyr-rex.tail2cfd9e.ts.net` hostname (PID 1042); three fresh tyr-to-ymir authenticated Rex requests
reported principal `tyr`, and a fresh eir-to-tyr authenticated connection passed. CLI checks used
`--autostart=false` to avoid creating a separate server. Heimdall's proxy and companion routing
service remained active, and its neighbor table confirmed the reserved client MAC.

This passes the scoped tyr IPv4 client reboot/recovery gate. It does not establish unattended
FileVault unlock or Rex application autostart, nor test a Heimdall reboot, proxy failure under
client traffic, general UDP/QUIC, IPv6 forwarding, full-network rollout or long-term stability. No
further configuration activation was performed during these post-boot checks.

#### Heimdall reboot — generation 10 recovered

Read-only preflight confirmed generation 10 is both the active system and the default EFI boot
entry, with `/boot` mounted from the existing EFI partition. Before this restart the booted system
was still historical generation 5
(`/nix/store/6wcbk8axznf4pdf7yvslma78nn7bq3rp-nixos-system-heimdall-26.11.20261111.d4f25a3`);
previous switches did not reboot the host. Its kernel and initrd resolve to exactly the same store
paths as generation 10. Sing-box, the pilot routing service, networkd and resolved are enabled; no
failed system units were reported. The shared profile persists Fake-IP mappings in its cache.

Do not use that historical booted generation as an automatic rollback: it belongs to the archived
gateway implementation. Generation 8 remains the minimal recovery baseline. An independent client
fallback was proposed; the user explicitly declined further tyr recovery changes and accepted that
tyr would remain without gateway access if Heimdall did not recover. No client fallback was armed
and no tyr or Flint settings were changed for this restart.

Heimdall was then restarted with that explicit approval. Its boot ID changed from
`4c3701b0-938b-436e-b953-fdcc81680d2b` to `a057103d-1cbf-418c-b8db-942dada8b170` on 2026-11-24
(checked at 12:21 UTC). LAN SSH returned on the first probe after a 20-second observation pause;
this is not a precise outage-duration measurement. Both booted and current system links now point to
generation 10. Sing-box, the companion route service, resolved, networkd and native tailscaled were
active; no failed units were reported. IPv4 forwarding, the scoped priority-5100 rule, table-2023
route, LAN TCP/UDP DNS listener and both firewall rulesets recovered automatically.

From tyr, unchanged `.161`/gateway-DNS `.2`/IPv6-off/proxy-flags-off settings were verified. UDP/TCP
DNS and Google (204), Baidu (200), Bilibili (200) HTTPS all passed with valid TLS. The scoped
forwarding counter increased. Native Heimdall Tailnet SSH and the host mixed-proxy path to ymir-rex
HTTPS (404 with valid TLS) also passed.

The first tyr-to-ymir Rex request timed out during TLS negotiation. Subsequent read-only checks
showed the native `utun0` route and an online peer with a LAN endpoint; three fresh authenticated
Rex requests then passed without changing routes, settings or issuing a preparatory peer ping. Fresh
inbound eir-to-tyr Rex also passed. Record the initial timeout as an unresolved transient, not
uninterrupted application availability. This establishes reboot recovery of the scoped IPv4 gateway,
not full-network, IPv6, general UDP/QUIC, proxy-stop failure or long-term stability acceptance.

#### QUIC and non-DNS UDP samples — passed

Read-only protocol probes were run from tyr with its unchanged manual gateway/DNS `.2`, IPv6 off and
system proxy flags off. Its installed curl supports HTTP/3. Two rounds against each of
`https://www.google.com/generate_204` and `https://www.cloudflare.com/cdn-cgi/trace` used:

```sh
curl -4 --interface en1 --noproxy '*' --http3-only --fail -sS \
  --connect-timeout 6 --max-time 15 -o /dev/null \
  -w 'HTTP=%{http_code} VERSION=%{http_version} TLS=%{ssl_verify_result}\n' "$url"
```

All four requests exited 0 with `VERSION=3`, valid TLS, Google 204 and Cloudflare 200. Durations
were approximately 0.32–0.40 seconds. `--http3-only` forbids TCP fallback; ordinary HTTPS success
alone was not treated as QUIC evidence.

Independent Python UDP sockets bound to `192.168.8.161` sent two small STUN Binding Requests each to
`stun.cloudflare.com:3478` and `stun.l.google.com:19302`. All four replies matched the success
message type, magic cookie, unpredictable transaction ID and declared response length, and included
a mapped-address attribute. Only validity and timing were reported, not mapped public addresses.
Response times were approximately 183–593 ms. No routes, proxy selections, firewall rules or client
settings were modified; Heimdall's services remained active with no failed units reported.

These samples validate QUIC/UDP 443 and non-DNS UDP 3478/19302 on the current gateway path. They do
not establish arbitrary UDP-port support, gaming/VoIP behavior, fragmentation/MTU behavior,
throughput, all upstream nodes, IPv6 or long-duration stability. Deliberately stopping the proxy to
test failure containment and recovery remains a separate, explicitly approved operation.

#### Controlled proxy stop and independent timed recovery — passed

With explicit user approval, a transient systemd timer on Heimdall was armed and verified active
before stopping sing-box. It was configured to start sing-box after 90 seconds, independently of
SSH/Rex control connections. Tyr and Flint settings were not modified and no client fallback was
installed.

Before stopping the core, tyr's curl bound to `en1` fetched `https://one.one.one.one/` using
`--noproxy '*' --resolve one.one.one.one:443:1.1.1.1`, returning HTTP 200 with valid TLS. While the
core was stopped, the same DNS-independent request timed out after five seconds (exit 28, HTTP 000).
The early forwarding guard's non-TUN output drop counter rose from 28 to 1474 packets during the
outage; this includes other pilot traffic, not only the probe. The companion routing service stopped
and its table-2023 route disappeared. Both LAN and native Tailnet SSH to Heimdall remained usable.
This exercised blocking new outbound connections, not an established long-lived stream.

No manual start was issued. The timer's service journal records automatic recovery at 2026-11-24
12:34:06–07 UTC. Sing-box and its companion service became active, and the scoped policy rule, route
and LAN DNS listeners were present. The fixed-address HTTPS request again returned 200; DNS over
UDP/TCP, Google HTTP/3-only (204, version 3), Baidu HTTPS (200), authenticated tyr-to-ymir Rex and
inbound eir-to-tyr Rex all passed. No failed units remained. The one-shot recovery units were
automatically collected; a subsequent check confirmed the timer was not loaded/inactive.

This was an operator-requested stop with a test-only recovery timer, not proof of every crash,
failed-start, prolonged upstream outage or resource-exhaustion recovery case. No permanent watchdog
or fallback policy was added. Long-lived connections, additional UDP applications, IPv6,
full-network rollout and long-duration stability remain outside this bounded acceptance.

#### Eir server admission — generation 11

The user requested an eir trial as well. Live inspection found eir on Wi-Fi `en0` at
`192.168.8.116/24`, not the historical `.34`. Heimdall's LAN neighbor table identified source MAC
`c6:a0:1f:ba:9a:53`; the macOS hardware MAC and the local interface's masked MAC are not suitable
substitutes for this admission rule. The user confirmed saving and applying the `.116` reservation
for this MAC on Flint. The guarded client cutover is recorded below.

`hosts/heimdall/gateway.nix` now declares an explicit two-client list. Each client requires its own
IP/MAC pair for DNS and forwarding, with its own early non-TUN/drop guard. Tyr retains rule priority
5100; eir uses 5101, sharing the existing table-2023 route and lifecycle service. There is no
subnet-wide admission or DHCP/NAT change. Assertions cover the added pair and the two scoped policy
rules. Default regressions passed and the candidate system built successfully on Heimdall:
`/nix/store/wzg2m20y1h8j9wxa3nm04lgxvgyyr65j-nixos-system-heimdall-26.11.20261111.d4f25a3`. After
guarded test activation, this system was switched as generation 11 at 12:54:27 UTC on 2026-11-24.
Eir's UDP/TCP DNS queries passed and its IP/MAC-scoped input counter increased; tyr's Google HTTPS
probe and fresh Heimdall native Tailnet SSH also passed. Both policy rules and per-client early
forward guards were present, with no failed system units. The server rollback timer was cancelled
after switch. Generation 10 remains the previous tyr-only server baseline.

Eir's baseline was DHCP router `.1`, DHCP DNS, automatic IPv6, native `CorpDNS=true` and Surge
enhanced mode on. Initial global `scutil --proxy` flags were off, but the Wi-Fi service's stored
HTTP/HTTPS/SOCKS settings were all enabled. The first preflight detected this difference and exited
before changing the network. The revised script saved each service-level flag explicitly for
restoration instead of inferring it from the effective global state.

#### Eir client trial — settings retained

An independent five-minute local launchd fallback was armed before cutover, with DHCP recovery and
reserved-address/static-Flint fallback. Eir then used manual `192.168.8.116/24` on `en0`, gateway
and DNS `.2`, IPv6 off and `CorpDNS=false`. Surge enhanced mode and the three system proxy flags
were disabled; the application itself was not terminated. The agent environment contained no
HTTP/HTTPS/ALL_PROXY variables, and the control session remained usable through the cutover.

UDP/TCP DNS, Google (204), Baidu (200), Bilibili (200), and Google HTTP/3-only (204, version 3)
passed with valid TLS. Three fresh eir-to-ymir authenticated Rex calls reported principal `eir`; a
separate command on tyr verified authenticated inbound access to `eir-rex`, reporting principal
`tyr`. Heimdall's eir-scoped forwarding counter increased and the retained settings were
independently checked before KEEP. The guard was removed and the administrator shell exited. Record:
`/private/tmp/heimdall-eir-persistent.Pb9IEaWP`. No special peer routes were added.

`hosts/eir/config.nix` now declares `acceptDns=false`, but **the Darwin declaration has not yet been
deployed on eir**: inspection of its installed boot helper still found `--accept-dns=true`. Do not
claim reboot persistence until the DNS declaration/startup wrapper is reviewed and deployed,
followed by a separate reboot check. Eir is a laptop; these manual Wi-Fi service settings can affect
other networks. Restore DHCP/DNS before leaving this LAN or ending the trial, and revert eir's pilot
DNS declaration when returning permanently to its prior configuration.

#### Shared encrypted service policy — generation 12

The user requested a persistent US-only game policy shared by sing-box profile consumers, not a
Heimdall-specific public override. The initial unactivated host-template edit was removed. The
policy is stored only in the encrypted `singbox_policy` field of `secrets/services/proxy.yml`.
Public modules/scripts implement generic credential loading and policy composition; no private node
membership or domain list is evaluated into a Nix derivation. Generation and subscription refresh
both receive the same policy through systemd credentials. Restricted URL-test membership is
explicit; changing subscription labels requires a corresponding encrypted policy update.

Default regressions, the actual core's private-policy reference/syntax check, and the remote system
build passed. A guarded test activation and permanent switch completed at 13:38:44 UTC on
2026-11-24, retaining generation 12:
`/nix/store/8vwdcqcrqakg2hw0zzn09p2hg5ng9bzm-nixos-system-heimdall-26.11.20261111.d4f25a3`. The
US-only group and its selected member were checked via the authenticated loopback controller without
printing credentials. A held TLS connection from eir to the game's website was observed using both
the private group and an allowed member. The website returned 302 with valid TLS; eir/tyr external
HTTPS, native Heimdall Tailnet SSH, companion route and service health passed. The rollback timer
was cancelled after switch. Other hosts were not activated.

The user must restart the launcher and confirm actual gameplay/region acceptance. These checks do
not prove account-country eligibility, full gameplay endpoint coverage, or sustained game sessions.
The previous two-client generation 11 is the rollback baseline. Client network settings and eir's
still-pending Darwin boot-helper declaration were not changed by this deployment.

#### Tailnet WebUI — generation 13

Heimdall enables the existing `profile.tailnet.webUI` Serve integration only by default for the
sing-box backend. This publishes MetaCubeXD and its controller through the native host identity, not
the embedded proxy identity. Existing Serve configuration was empty before activation. The
controller still listens only on `127.0.0.1:9090`; no LAN firewall port or Funnel was enabled.

After regression checks (including dae fallback), remote build, guarded test activation and HTTPS
checks, generation 13 was retained at 14:18:55 UTC on 2026-11-24:
`/nix/store/pzjhv8v5752vs8x1lbiyx8zcpxw3l1hl-nixos-system-heimdall-26.11.20261111.d4f25a3`. The
rollback timer was cancelled. Eir and tyr both fetched the UI with status 200 and valid TLS:
`https://heimdall.tail2cfd9e.ts.net/ui/`.

The backend address is `https://heimdall.tail2cfd9e.ts.net`. Supply the SOPS-managed controller
secret privately in the UI, never in a URL or chat. An unauthenticated `/version` request
returned 401. Authenticated HTTPS `/version`, `/proxies`, `/connections` and the first `/traffic`
streaming record passed from Heimdall, without exposing credentials. Browser login/interactions and
WebSocket behavior remain user acceptance checks. General eir HTTPS, the pilot route and system
service health also passed. Generation 12 is the previous no-WebUI rollback baseline; neither
cold-boot validation nor eir's pending Darwin boot-helper synchronization was performed here.

#### Manual game selector trial — rolled back

The user subsequently requested a generic manually selectable game group, initially selecting the
first approved US node. Only the encrypted policy was changed; the existing generator already
supports selector membership expansion. Candidate
`/nix/store/3cclz6ydrvp1q9lf18a694nkj7hq013s-nixos-system-heimdall-26.11.20261111.d4f25a3` built and
passed guarded test activation, but was not committed to the system profile. After the user reported
loss of connectivity, the operator immediately restored generation 13 with a test activation rather
than continuing the rollout.

Post-restore checks from eir passed UDP DNS, Google HTTPS (204), Baidu HTTPS (200) and the WebUI
(200), all HTTPS checks with valid TLS. Tyr's Google HTTPS check also passed. The pilot route and
services recovered, no failed units were reported, the profile still points to generation 13, and
the candidate rollback timer is inactive. Proxy restart interruption is a possible contributor, not
an established explanation of the reported outage. At this stage the encrypted selector edit was
pending, not retained live; activation was deferred. The subsequent authorized retry is recorded
below.

#### Flint-backed management and manual game selector — generation 14

The user enabled Surge and authorized moving eir back to Flint before retrying deployment. Merely
enabling Surge had left the physical Wi-Fi gateway pointing at Heimdall. A locally guarded switch
changed only eir's manual IPv4 router and DNS to `192.168.8.1`, retaining `.116/24`, IPv6 off,
existing Tailscale preferences and Surge settings. Physical interface routing via `.1`, external
HTTPS and LAN management were verified before KEEP; the local fallback was removed. Record:
`/private/tmp/eir-flint-before-game.ZgcUiWHg`. Eir was not automatically switched back afterward.

The same candidate from the first trial was then test-activated under a fresh server rollback timer,
verified and retained as generation 14 at 14:54:06 UTC on 2026-11-24:
`/nix/store/3cclz6ydrvp1q9lf18a694nkj7hq013s-nixos-system-heimdall-26.11.20261111.d4f25a3`. The
previous automatic game group is replaced by a manual selector with the first approved US node as
its configured default and observed selection. The controller exposed 32 node choices, and a PUT
reselecting the current node returned 204. No other group's selection was changed. A held TLS
connection from tyr to the game website was observed using the new group and its expected node. Tyr
external HTTPS, WebUI TLS, companion route and service health passed; the rollback timer was
cancelled after switch.

Panel users can refresh the group list and choose another node. Existing cache configuration
persists selector choices; the default is not intended to overwrite later user selections. Eir
currently uses Flint plus Surge, so ordinary eir game traffic does **not** test this Heimdall
policy. Gameplay acceptance, the earlier outage's root cause, and eir's Darwin boot-helper work
remain unresolved. Switching eir back to the gateway requires a separate agreed client cutover.

#### Eir returned to Heimdall — both Surge takeover modes off

The first return attempt passed its probes but timed out awaiting KEEP while the conversation
continued on another topic. It reverted to Flint; this was not a retained gateway trial. A later
live inspection confirmed Flint routing and active Surge takeover, explaining why the gateway's game
group could not control ordinary eir launcher traffic at that point.

For the subsequent authorized cutover, administrator authorization was completed before starting the
timed guard. Independent checks caught Surge enabling system proxy takeover after enhanced mode was
disabled, despite earlier `networksetup` proxy-off commands. That attempt was not retained. Its
fallback initially could not re-enable enhanced mode while macOS network reconfiguration was
settling; restoration was completed and the stale guard removed. The script was amended to save
Surge's system-proxy preference, disable both feature switches, check effective proxy flags and
retry restoration readiness within a fixed bound. One further attempt restored Flint after a Tailnet
WebUI connection timeout; it is not evidence of uninterrupted Tailnet availability.

The retained attempt passed all immediate probes, including the WebUI without a retry. Eir now uses
`.116/24`, router/DNS `.2`, IPv6 off and unchanged `CorpDNS=false`. Both Surge features are off, and
effective HTTP/HTTPS/SOCKS flags are zero. Fresh authenticated eir-to-ymir and tyr-to-eir Rex calls
passed. KEEP was sent during the same verification sequence, confirmed in the terminal, and the
administrator shell exited. Record: `/private/tmp/eir-heimdall-game-trial.90z7lGte`. A held Nexon
website TLS connection from eir was independently observed in the gateway's game group. This
confirms the sampled route, not all launcher/game endpoints or successful character selection. The
installed Darwin boot-helper synchronization remains outstanding; no reboot check was performed.

#### Tyr subnet-only role — generation 604 retained

The user requested moving exit-node duties to Heimdall and explicitly changing tyr to
`subnet-router`. `hosts/tyr/config.nix` now retains only that role, preserving its existing
`192.168.1.0/24` advertisement and pilot DNS preference. A scoped
`tailscale set --advertise-exit-node=false` succeeded on tyr: preferences showed only the existing
subnet, no selected upstream exit node, and `CorpDNS=false`. This did not change Wi-Fi routing. The
advertised subnet was preserved as requested, not newly validated for reachability.

A candidate was built from the retained baseline, changing only the role while preserving the
earlier DNS and boot-wait fixes:
`/nix/store/93baa2y3q2nx4a3il3gs64yrmvbv058b-darwin-system-26.11.ff0e21a`. Unprivileged closure
import was rejected for lack of a trusted signature. The four new store paths were staged as a NAR
for explicit administrator import. Guarded installation verified identical unrelated system
components and that the helper differs only by removal of the exit advertisement flag. The helper
exited 0, native daemon PID and node identity stayed unchanged, and DNS/subnet preferences, web
access and an independent authenticated outgoing Rex call passed. The plist and matching profile/
current-system pointers were retained as generation 604 at 23:40:41 local on 2026-11-24, without
full Darwin/Homebrew activation. KEEP was confirmed, the guard removed and the root shell exited.
Record: `/private/tmp/tyr-subnet-activate.ckqc6YFa`. A reboot was not performed. Heimdall's later
exit-node deployment is recorded in [exit-node operation](exit-node.md); native advertising alone is
not evidence of full remote forwarding/DNS acceptance.

For manual rollback on tyr, restore DHCP, automatic IPv6 and the former proxy settings:

```sh
sudo networksetup -setdhcp Wi-Fi
sudo networksetup -setdnsservers Wi-Fi Empty
sudo networksetup -setv6automatic Wi-Fi
sudo /run/current-system/sw/bin/tailscale set --accept-dns=true
sudo networksetup -setwebproxystate Wi-Fi on
sudo networksetup -setsecurewebproxystate Wi-Fi on
sudo networksetup -setsocksfirewallproxystate Wi-Fi on
/opt/homebrew/bin/surge-cli feature set enhanced-mode on
```

If DHCP is unavailable, use the reserved `192.168.8.161/24` manually with gateway and DNS `.1` until
Flint DHCP is repaired. Revert tyr's `acceptDns=false` declaration when ending this pilot so future
rebuilds match the restored DNS ownership. Restore the client before rolling Heimdall back to
generation 9, since that baseline does not forward LAN client traffic.

## Raw-IP game routing correction — generation 16

The user reported that MapleStory worked with an American `Proxy` selection but failed after
character selection when `Proxy` used Taiwan, despite `Game` using an American node. Inspection
found game login/domain connections already matched `Game`, while subsequent raw-IP TCP connections
from eir followed the selected fallback node. Historical records showed the same game endpoints
using Taiwan before the selector change and America afterward.

Only the SOPS-encrypted `singbox_policy` in `secrets/services/proxy.yml` was extended: one TCP rule
routes six observed exact IPv4 `/32` destinations to `Game`. There is no cloud-provider-wide prefix,
blanket port rule or host-local plaintext override. Domain rules, selector defaults and other policy
sections are unchanged. This is a bounded correction for observed endpoints; new server addresses
can still require evidence-backed additions.

The real generator and sing-box core validated the candidate privately. Comparison against the live
JSON found exactly one added routing rule and no other configuration differences. Default
regressions and the host build passed. An initial transient activation launcher lacked `PATH` and
failed its preflight before touching the system; after correcting that launcher, test activation
succeeded under a five-minute independent rollback timer. The phone capture had already ended.

An eir TCP probe to an observed game target matched `Game`, used its retained America-01 selection,
and received a 21-byte server greeting. `Proxy` remained America-02, proving this new connection did
not merely follow the global fallback. This is route/greeting evidence, not full character-entry
acceptance. Eir Google/Baidu, tyr Google, authenticated-host native SSH, WebUI TLS and all gateway
route services passed. Both exit-table defaults and unreachable fallbacks remained installed.

Generation 16 was retained at 20:20:06 UTC on 2026-11-24:
`/nix/store/jsmk7lr6pgd6hm3my703x7j1chip8xvx-nixos-system-heimdall-26.11.20261111.d4f25a3`. The
rollback timer was cancelled. Generation 15 remains the game-change rollback baseline. The user
subsequently confirmed that gameplay works. Manual selectors were not changed by the deployment; the
earlier raw-IP probe is separate from this user acceptance. Operational records:
`/private/tmp/heimdall-game-exit-fix` on eir. Cellular exit acceptance remains unresolved; see
[exit-node diagnostics](exit-node.md).

## IPv4-only-uplink compatibility — generation 17

With user approval, the validated candidate was deployed under a five-minute automatic rollback and
retained at 21:18:08 UTC on 2026-11-24:
`/nix/store/r6i0pk8cq5ygy3vz57harwfgrrvmh8rg-nixos-system-heimdall-26.11.20261111.d4f25a3`. Direct
outbound domains now resolve to IPv4; otherwise-unmatched public IPv6 literals use `Proxy` before
the domestic direct fallback. Existing private/service policy retains priority. Game rules and
manual selections, kernel exit containment, native Tailscale transport and client settings were not
changed. Eir/tyr HTTPS, WebUI, native SSH, gateway services and routes passed. A verified-TLS
IPv6-literal SOCKS request returned HTTP 204 and matched the new fallback in the controller. The
rollback timer was cancelled; generation 16 remains the immediate rollback baseline. This sample
does not prove remote-phone performance or reboot reliability. Full details and remaining cellular
limitations are in [exit-node operation](exit-node.md).

## Phone trial failure and rollback — generation 18

The user reported domestic and international sites unreachable after the generation-17 trial. The
generation-16 closure was restored as generation 18 at 21:22:12 UTC. Eir HTTPS and the WebUI passed,
and gateway services were active; the phone's discovery/TSMP/HTTP probes still timed out with a flat
receive counter. The host's `ipv4OnlyUplink` opt-in was removed, preserving the game correction. The
IPv6 experiment did not establish a fix and must not be automatically reapplied. Upstream iOS
MagicSock/data-plane stall reports and a maintainer-provided TestFlight fix candidate are recorded
in [exit-node diagnostics](exit-node.md). No mobile release-channel change was made.

## Archived work

All removed Heimdall work remains in Git stash `1290daee42dd7e15b09b9e56cbbd23aa7bf4ffce` (including
its untracked-file parent). Do not pop the whole stash over these minimal files unless intentionally
restoring the gateway implementation.
