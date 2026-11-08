# Network ownership, diagnostics and staged changes

This guide covers NixOS network ownership, the behavior-preserving refactor and the separately
approved LLMNR hardening, iwd ownership changes and nftables trial below. It does not claim that a
build has been activated or that coexistence of network managers is always correct. See the
[shared proxy profile](proxy/shared-profile.md) and [ymir deployment guide](proxy/ymir-sing-box.md)
for proxy-specific rules and identities.

## Scope of phase one

- `networking.useNetworkd` and `networking.networkmanager.enable` remain enabled by default where
  they were before, but use `mkDefault` so a host can override them normally.
- No host changes manager, DNS path, routing, firewall, iwd configuration, SSH policy or dae state.
- The old bundled TCP preset is removed. Three independent tuning options default to `null`,
  contributing no sysctls or modules until explicitly selected.
- Tests inspect declarations; diagnostics only query runtime metadata. Neither activates anything.

Do not turn off a manager merely because another one is enabled. Check interfaces, DHCP/RA, resolver
integration, generated units and host-specific overrides first. Changing a default into an
overridable value is not a complete manager migration.

### Approved follow-up: disable LLMNR

The shared resolved module now declares `settings.Resolve.LLMNR = false`. This reduces exposure to
unauthenticated link-local name resolution and may affect LAN short names that rely on LLMNR. It is
not a DNS performance change and does not change mDNS, unicast DNS servers, Fake-IP or Tailnet
routing. The installer does not import this shared module; WSL still has resolved disabled.

The existing wait-online settings and `stopIfChanged = false` values are retained. The latter select
restart under the new configuration instead of stop-old/start-new; they do not prevent restarts. No
scripted `network-addresses-*` units or reference-host interface names are added.

This follow-up changes the declaration baseline only for LLMNR. Verify required LAN names before a
separately authorized activation. Building the configuration does not change the running resolver.

### Approved follow-up: reserve Wi-Fi IP configuration for NetworkManager

The shared wireless module now sets `iwd.settings.General.EnableNetworkConfiguration = false`.
NetworkManager keeps its `iwd` backend: iwd handles Wi-Fi association and authentication, while
NetworkManager configures IP addresses, routes and DNS. All currently declared hosts with iwd
enabled also enable NetworkManager. The installer does not import this shared module; iwd remains
disabled on mimir and nidhogg.

This change is not activated by editing or evaluating the configuration. First activation may
restart iwd and interrupt Wi-Fi; use a local console or an independent recovery connection.
Disabling NetworkManager does not automatically enable standalone iwd IP configuration. A future
standalone iwd host must explicitly define network ownership and update the ownership tests.

### Approved follow-up: nftables declaration and ymir trial

`firewall.nix` now sets `networking.nftables.enable = true`. The shared declaration applies to
athena, loki, mimir, sigurd and ymir on their next activation. Nidhogg retains its forced-off WSL
exception; the installer does not import this module. Firewall enablement, allowed ports, Ping,
loose reverse-path checking and logging policy are unchanged. `flushRuleset` remains false so NixOS
does not flush other components' tables, and forwarding filtering remains disabled.

The shared module explicitly uses `mkDefault` for firewall enablement, allowing Ping, loose
reverse-path checking, and disabling reverse-path/refused-connection logging. Hosts can override
these defaults normally, subject to other modules' requirements: Tailscale client routing also sets
`checkReversePath = "loose"`, so changing that value requires coordinating its configuration.
Service modules still own their port openings; no empty lists or forced reverse-path overrides are
added.

Upstream also changes libvirt's default `firewallBackend` to nftables. Existing libvirt network
rules are not proof that a newly started virtual network will use the same backend. Docker and
Tailscale can retain their own iptables-compatible tables; do not flush or rewrite them manually.

#### Local trial on 2026-11-08 — restored, not permanently switched

- Built the ymir toplevel and generated nftables rules successfully. The tested closure was
  `/nix/store/6dwlcm9cak5gq9fz4gmv9ngwsmswy50n-nixos-system-ymir-26.11.20261103.1d06008`.
- Retained the previous closure with a GC root, verified a dry rollback invocation through systemd,
  and armed a ten-minute rollback timer before `test` activation. No boot default was changed.
- Confirmed `nftables.service` active and the `inet nixos-fw` table installed. The old NixOS
  iptables input/rpfilter hooks were removed; Docker, libvirt and Tailscale tables remained.
- Domestic/public HTTPS, IPv6 HTTPS, Nix cache access, DNS, the LAN gateway, explicit mixed-proxy
  access and local WebUI matched the pre-test baseline. Authenticated controller access returned
  200; unauthenticated access returned 401. Credentials were not printed or passed in arguments.
- From athena, new TCP connections received SSH banners on ports 22 and 2222, Tailnet HTTPS WebUI
  returned 200, and the unauthenticated API returned 401. This checks inbound reachability, not a
  new SSH user-authentication flow. HTTPS used an explicit address mapping because athena did not
  resolve ymir's Tailnet hostname; certificate verification remained enabled.
- Reloaded nftables and repeated connectivity/inbound checks successfully. NetworkManager, iwd,
  networkd, resolved, tailscaled and user Rex PIDs were unchanged. Sing-box and Fail2Ban restarted
  during activation. The recreated TUN changed its interface index, not DNS or routing policy.
- Restored `/nix/store/d16r1fr1c3c6wgzf376mp4lb19bv1dc2-nixos-system-ymir-26.11.20261103.1d06008`,
  verified restored firewall hooks and connectivity, then cancelled the rollback timer. No failed
  system units remained. The running system and default boot generation still use the old backend.

No containers or virtual machines were running during the trial. Their traffic, libvirt network
recreation, cold boot, other hosts, and inbound Rex application sessions remain unverified. Do not
interpret this bounded trial as approval to activate the shared change everywhere.

## Declared ownership inventory

The baseline was evaluated at `ac8360b`. This table records declarations, not live ownership or
reachability on every machine. The installer uses its own configuration rather than the shared
`dot.networking` modules.

| Host          | NetworkManager | networkd | Declared networkd interfaces         |
| ------------- | -------------- | -------- | ------------------------------------ |
| athena        | on             | on       | `eth0`, unmanaged `tailscale0`       |
| installer     | on             | off      | none                                 |
| loki          | on             | on       | unmanaged `tailscale0`               |
| mimir         | off            | on       | Ethernet match in `10-microvm`       |
| nidhogg (WSL) | off            | off      | none; preserve Windows/WSL ownership |
| sigurd        | on             | on       | unmanaged `tailscale0`               |
| ymir          | on             | on       | unmanaged `tailscale0`               |

Relevant modules:

- [default.nix](../modules/nixos/networking/default.nix): shared defaults; existing WSL DHCP
  behavior is retained.
- [systemd.nix](../modules/nixos/networking/systemd.nix): resolved and optional networkd DHCP
  definitions from `dot.device.ethernetDevices`.
- [networkmanager.nix](../modules/nixos/networking/networkmanager.nix): NM, resolver integration,
  Wi-Fi backend and interface exclusions.
- [firewall.nix](../modules/nixos/networking/firewall.nix): explicit firewall enablement and the
  shared nftables declaration, with the WSL exception retained.
- [wireless.nix](../modules/nixos/networking/wireless.nix): iwd Wi-Fi settings; built-in IP
  configuration is disabled by the approved follow-up.
- [proxy/profile.nix](../modules/nixos/networking/proxy/profile.nix): selected TUN exclusion and
  resolved-to-core DNS path.

### ymir boundaries

```text
Physical Wi-Fi/IP configuration -> NetworkManager (iwd Wi-Fi backend)
System resolver entry          -> systemd-resolved
Proxy DNS and sb-tun routing    -> sing-box
System Tailnet interface/rules -> tailscaled
networkd declaration           -> do not manage tailscale0
```

This is the declared division, not proof of the currently running configuration. Preserve:

- resolved forwarding to `127.0.0.1:1053`, no fallback DNS, and DNSSEC disabled;
- loopback mixed/controller listeners and authenticated private Tailnet Serve;
- the distinct system, embedded-core and Rex identities;
- Tailscale transport bypasses and inbound replies, including priorities 5260/5261 and table 2022;
- dae disabled, with no automatic interception changes.

### Open ownership questions, not changes in this phase

- athena declares networkd DHCP on `eth0`, while NM is enabled without an explicit `eth0` exclusion.
  Inspect live ownership before changing either manager.
- Review libvirt/container interfaces individually. NM's `connected (externally)` is not proof it
  acquired the address. Do not blindly exclude all bridges: some may intentionally belong to NM.
- `ManageForeignRoutingPolicyRules`, `ManageForeignRoutes`, and `ManageForeignNextHops` remain
  unset. Evaluate their lifecycle effects before explicitly disabling networkd cleanup globally.
- The original refactor did not migrate nftables. The separately approved trial above changes the
  backend, including upstream backend-dependent Fail2Ban defaults, without changing SSH policy.

## Independent tuning options

The options live in [tuning.nix](../modules/nixos/networking/tuning.nix):

| Option under `dot.networking.tuning` | Values                           | Default |
| ------------------------------------ | -------------------------------- | ------- |
| `congestionControl`                  | `null`, `reno`, `cubic`, `bbr`   | `null`  |
| `defaultQdisc`                       | `null`, `fq`, `fq_codel`, `cake` | `null`  |
| `mtuProbing`                         | `null`, `0`, `1`, `2`            | `null`  |

`null` leaves the existing kernel/NixOS setting alone; it does not select a new default. Each option
writes only its corresponding sysctl. Selecting BBR adds `tcp_bbr`; selecting a qdisc adds its
`sch_*` module. Other algorithms and specialized parameters can use native NixOS options rather than
growing another tuning bundle. Kernel support still needs validation on the target host.

- Qdisc is a host default, not limited to TCP. It does not replace existing interface qdiscs and
  does not configure CAKE bandwidth shaping. Compare the actual `tc` state, not just the sysctl.
- MTU probing: `0` disables it, `1` enables black-hole recovery, `2` always probes. It does not
  replace correct tunnel MTU configuration.
- Changing the local congestion algorithm does not control a remote download sender's algorithm.
- IPv6 RA, reverse-path checks, TCP timestamps, TFO, buffers and conntrack timeouts are not changed
  by these options. Manage interface policy separately and measure before changing kernel defaults.

No current host selects these options. A later, separately approved experiment could set only:

```nix
dot.networking.tuning.congestionControl = "bbr";
```

Do not enable several experimental settings at once. Keep the current qdisc and measure connection
success, latency under load, upload/download throughput, CPU and memory before adding another
change.

### Migration from optimizeTcp

`dot.networking.optimizeTcp` is deleted without a compatibility or removed-option module. Remove old
assignments, including `optimizeTcp = false`. None of the current hosts used the option. There is no
automatic translation of `true`: that preset also disabled IPv6 RA, enabled strict reverse-path
checks, changed timestamps, queues and connection-tracking timeouts. Recreating it would retain the
risks this refactor removes.

## Read-only runtime inventory

Run on the Linux host, as the normal user whose Rex service you want to inspect:

```sh
umask 077
python3 scripts/network-diagnostics.py > /tmp/network-before.json
```

The script uses Python's standard library and queries installed `ip`, `tc`, `nmcli`, `networkctl`,
`resolvectl`, `systemctl`, `sysctl` and Git. It does not install tools or require sudo. Missing
tools, permissions, unsupported JSON formats and five-second command timeouts produce partial data
plus an `errors` list. Missing sysctl keys are listed separately. Exit success means a report was
produced, not that the network is healthy.

It reports:

- running/booted system symlink targets, kernel and checkout revision;
- allowlisted service state/PID/restart fields, including user Rex;
- link state, actual qdisc kinds, NM device state and networkd administrative state;
- DNS server addresses/ports, routing domains and selected resolver flags;
- IPv4/IPv6 rule priorities, table IDs and source/destination-scoping flags;
- route counts/default-route counts grouped by table, device, protocol and route type;
- nexthop IDs/devices and selected read-only kernel parameters.

It does **not** directly read daemon configuration or secret files, journals, subscriptions,
controller tokens, Wi-Fi profiles or other processes' environments. It does not call a proxy API,
resolve test domains or send network probes. Query error output is suppressed. It excludes interface
MACs, route destination/gateway addresses and NM connection names/SSIDs. It is not a complete
anonymizer: DNS domains/servers, interface names and store paths are network metadata. Review the
report before sharing it.

No runtime health is inferred from service activity. Checkout revision and running generation may
not correspond; embedded Tailnet authorization is not proven by system tailscaled being active. The
script does not inspect iwd configuration. Review that separately through the selected Nix options
rather than dumping runtime configuration files.

## Evaluation and regression tests

```sh
nix --extra-experimental-features pipe-operators eval --impure --json \
  --file scripts/tests/networking.nix checks
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s scripts/tests -p 'test_network_diagnostics.py'
bash scripts/tests/test-mihomo-tailnet-routing.sh
nix --extra-experimental-features pipe-operators eval --impure --json \
  --file scripts/tests/dae.nix
```

The network tests cover null defaults, independent/combined settings, invalid options, ordinary
manager overrides, current host defaults, shared-module LLMNR hardening, iwd/NetworkManager
ownership, nftables scope and firewall-policy preservation, and ymir DNS/Tailnet/dae invariants.
Diagnostic tests use fake command responses and restrict calls to fixed read queries. They verify
field selection, unavailable tools, malformed responses, timeouts and suppression of error output.
The routing test operates in a disposable network namespace, never the host namespace.

For a private declaration comparison, capture this output before and after a change:

```sh
umask 077
nix --extra-experimental-features pipe-operators eval --impure --json \
  --file scripts/tests/networking.nix hosts > /tmp/network-declarations.json
```

The declaration inventory includes interface matches, DNS, manager flags, iwd, nftables, network
sysctls and kernel modules. It does not prove that every host has deployed those settings. Ordinary
manager override checks do not replace a complete build and runtime validation of a new manager
layout. The baseline refactor preserved all seven host snapshots. The approved LLMNR follow-up
changes only that setting within the inventory. The later iwd follow-up changes only its
`EnableNetworkConfiguration` setting; manager enablement and DNS/proxy paths stay unchanged.

Build without activation:

```sh
nix --extra-experimental-features pipe-operators build --no-link \
  .#nixosConfigurations.ymir.config.system.build.toplevel
```

## Later deployment: acceptance and rollback gates

The following are a plan for a separately authorized deployment, not actions performed by the
first-phase refactor or diagnostic script.

1. Keep a local console or independent recovery channel. Save the actual current system path and
   retain its closure with a GC root. Confirm the previous generation's credentials remain usable.
2. Build and review the change, including generated service dependencies and what activation may
   restart. Existing `stopIfChanged` flags are not a guarantee that networking cannot be
   interrupted.
3. Prepare a timed rollback to the saved known-good generation and test the recovery procedure
   before relying on it. Do not use only the same SSH/Rex connection being tested as the rescue
   path.
4. Capture the private diagnostic baseline. Record initial sing-box/Rex PIDs and generation paths.
5. Activate only the approved change. Do not mix a manager migration, proxy upgrade, tuning change,
   firewall migration and kernel reboot into one experiment.
6. Verify IPv4/IPv6, domestic/public/LAN access, DNS, system Tailnet inbound replies, SSH and Rex
   from another device. Check WebUI TLS, unauthenticated rejection and authenticated access without
   putting tokens in command arguments. Separately verify the embedded Tailnet identity if required.
7. Verify route/rule/nexthop ownership and resolver state. In a disposable VM first, exercise
   networkd/manager restart, proxy restart/stop/start, failed startup and network reconnection.
   Production restarts and fault injection require their own approval and rollback protection.
8. Compare diagnostics and application behavior. Only cancel rollback once the acceptance checks
   pass; schedule cold-boot validation separately. Do not claim reboot safety from a successful
   switch.

If access or DNS fails, restore the saved generation through the recovery channel. Merely stopping
sing-box is not a rollback: resolved still points at its DNS listener. Do not flush host routing
rules, reset Tailscale Serve, replace credentials or start dae as an improvised recovery step.
Preserve system `ymir`, embedded `ymir-singbox` and `ymir-rex` identities and their separate state.
