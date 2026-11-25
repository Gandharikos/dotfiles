# Heimdall: AdGuard Home before sing-box DNS

## Scope and ownership

Deployed with ads/tracking plus the requested **fakenews, gambling and porn** extensions; social is
not selected. **Generation 23** was retained at `2026-11-25T02:27:05Z`, adding the
behavior-preserving module extraction and proxy panel readiness fix. Runtime and the default profile
match: `/nix/store/lixx25fa1l703zi057sgrx3f4aqgarab-nixos-system-heimdall-26.11.20261111.d4f25a3`.
The last boot still used generation 22; no reboot accompanied generation 23. Deployment evidence is
recorded below; declarations alone are not proof of activation.

```text
LAN DHCP DNS 192.168.8.2:53 -> AdGuard Home -> sing-box 127.0.0.1:1053
Host resolved stub        -> AdGuard Home 127.0.0.1:53 -> sing-box
Native tailscaled ExitDNS -> Flint 192.168.8.1 (real addresses, unchanged)
```

AdGuard replaces resolved's extra LAN listener, not sing-box's internal resolver. The profile's
Fake-IP, selectors, encrypted game policy and embedded Tailnet identity remain unchanged. AdGuard
caching is disabled to leave mapping/cache lifetime with sing-box. There is no unfiltered fallback
resolver. Private reverse lookups/runtime rDNS discovery are disabled to avoid an OS-resolver loop.

Only IPv4 `192.168.8.0/24` arriving on `enp2s0` is admitted. The `ip heimdall-dns` prerouting NAT
chain redirects TCP/UDP port 53 passing through Heimdall to `.2:53`, before TUN hijacking. It does
not capture host-originated bootstrap DNS, native Tailnet exit traffic, same-L2 requests directly to
Flint/other LAN DNS servers, DoH/DoT, VPNs or Private Relay. This is domain filtering, not a content
classifier or tamper-proof parental control; same-domain ads/video ads can remain. DHCP stays on
Flint. No IPv6 gateway, public resolver or new trusted interface is introduced.

## Module ownership

The reusable preset lives in `modules/nixos/networking/adguardhome.nix`, discovered by the existing
network-module scanner. `dot.networking.adguardhome.enable` defaults to false. The only additional
options are `usersFile` (an absolute runtime JSON credential path outside the Nix store) and
`seedFile` (a public pinned file). It reuses upstream `services.adguardhome`; configure listeners,
upstreams and the single filter through that existing settings namespace rather than duplicate
wrapper options.

The shared module owns authentication injection, initial cache preparation, service safety defaults,
filtering defaults and local retention. It does not assume sing-box, SOPS, a LAN subnet, interface,
DNS port, HTTP port or Tailnet exposure. It requires explicit DNS binds/upstreams and a loopback
HTTP address. Hosts own credential provisioning and its service ordering.

`hosts/heimdall/adguardhome.nix` retains the exact subscription/seed selection, SOPS bindings, cache
policy for Fake-IP, LAN/upstream addresses, resolved override, DNS NAT chain, dependencies and
Tailnet Serve unit. `scripts/adguardhome-prepare.py` remains the common runtime helper. Existing
addresses, credentials, filter ID, rule variant and exposure are unchanged.

Validation froze the repository source path for both evaluations, avoiding irrelevant whole-source
store-path churn. Before/after AdGuard settings, generated units (AdGuard, its UI, sing-box,
tailscaled and resolved), DNS settings, firewall/NAT tables and SOPS declarations were identical.
Standalone tests exercise non-Heimdall ports/upstreams without sing-box/SOPS, disabled-module
inertness and rejection of missing/unsafe credentials, seeds, filter IDs and listeners. These checks
run in the default regression suite. The extraction was initially prepared without activation, then
deployed with the readiness fix in generation 23 below. Whole-source store-path changes did restart
sing-box and AdGuard during that deployment; semantic equivalence is not a promise of restart-free
activation.

## Filtering and persistence

- Subscription:
  <https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts>.
  This includes base ads/tracking plus fakenews, gambling and porn; no redundant base list or social
  extension. `networking.stevenblack` stays disabled: that option manages `/etc/hosts`, not AGH's
  subscription. Filtering remains owned by AdGuard, before Fake-IP resolution.
- AdGuard refreshes every 24 hours. The initial file is pinned to commit
  `81f6c19b6ae322732879d119e5cbdd8f8bf6c52c` with a fixed hash in Nix, so cold startup does not need
  to download its protection list. A fresh-mtime seed is installed only if cache `2.txt` is absent
  or empty; existing downloaded updates are preserved. The helper derives the filename from the
  configured filter ID. ID 2 deliberately replaces ID 1's porn-only subscription, preventing reuse
  of its older, narrower cache. Change IDs deliberately when changing subscription variants.
- The public subscription is a moving upstream list, not an immutable policy guarantee. Failed
  refreshes and false positives need monitoring. Use narrow domain exceptions, not broad provider
  IP/port bypasses. Browser, game login and actual gameplay still need user acceptance.
- Query logs and statistics stay local, retained for 24 hours. Cloud parental/safe-browsing checks
  are disabled. Administrators can see LAN query metadata in the authenticated UI.
- Mutable settings preserve UI-managed user rules/exceptions. Nix-owned upstreams/list/protection
  defaults are reapplied at service start. Authentication is injected after the Nix merge from a
  systemd credential; hashes and plaintext passwords never enter the Nix store.

## Management and credentials

UI: `https://heimdall.tail2cfd9e.ts.net:8443/`, proxied to loopback `127.0.0.1:3000` by native
Tailscale Serve. The existing sing-box UI on HTTPS 443 is independent. No Funnel, LAN UI opening,
profiling endpoint or plaintext DoH listener is enabled. The UI unit waits for native tailscaled
Running and owns only the root handler on 8443; it never resets other Serve mappings.

Administrator: `johnson`. A new random password and its bcrypt hash are encrypted in
`secrets/services/adguardhome.yaml`, scoped to the operator's age/PGP keys and Heimdall only. Do not
reuse or disclose the proxy controller token. The operator can retrieve the password in a private
trusted SSH terminal with `sudo cat /run/secrets/adguardhome_admin_password`; do not paste it into
chat, logs or command arguments. Only root can read that recovery secret; the service receives only
the users/hash JSON through `LoadCredential`. Password changes must update SOPS; startup
deliberately reapplies those credentials rather than accepting a conflicting UI-only change.

## Validation and rollback

Before activation: build/check the real AGH configuration, test preparation failure paths, validate
nft syntax and SOPS access, record the previous generation and private proxy/selector snapshot,
inspect the restart plan, and arm an independent rollback. Activation replaces the DNS owner and may
restart sing-box because the shared source path changes. Preserve all identity/state directories.

Verify LAN UDP and TCP DNS, ads/porn A and AAAA blocking, legitimate/Fake-IP/Tailnet answers, routed
external port-53 interception, HTTPS, controller auth and unchanged selectors/identities. Check
native ExitDNS separately for real answers. Confirm the pinned list loaded without an initial
network refresh and authenticated UI works while unauthenticated API access is rejected. Check
listener/firewall scope; active service status alone is insufficient.

Rollback the entire generation, restoring resolved's LAN listener and original upstream and removing
only the owned DNS NAT chain and Serve 8443 handler. **Restart systemd-resolved after changing its
extra listeners**: during this migration, reload alone left its UDP stub bound incorrectly and
`127.0.0.53:53` UDP refused queries; restarting restored both UDP and TCP. Include this restart in
the independent rollback script, not only the forward deployment. Do not merely stop AdGuard: that
would leave host/LAN DNS pointing at a dead listener. Preserve `/var/lib/AdGuardHome` for diagnosis.
Flint/client DHCP settings are unchanged, so this rollback does not require a lease migration.

## Readiness fix and module extraction — generation 23

The user approved the maintenance window. Default regressions and the remote toplevel build passed;
the candidate was protected by `/run/heimdall-readiness-candidate` until permanent retention. Dry
activation limited the stop/start set to sing-box, its Serve unit, AdGuard and SOPS installation.
Native tailscaled did not restart. An independent systemd dry-activation check passed, and a
ten-minute rollback to generation 22 was armed before test activation. The rollback restores the
profile/configuration and explicitly restarts resolved. LAN SSH remained available independently of
the proxy. Native Tailnet SSH requested interactive reauthentication and was not used as a verified
recovery path; no trust/authentication checks were bypassed.

- The proxy Serve unit now runs the bounded readiness helper, uses a 120-second startup timeout, and
  retries failures after 30 seconds. Its deployed state was active/success with zero automatic
  retries. Native tailscaled was already Running during activation: this does not exercise the next
  cold-boot race or prove arbitrary delayed-network recovery.
- One initial embedded-Tailnet DNS lookup returned NXDOMAIN; the bounded probe retried and passed.
  This separate embedded-endpoint readiness issue remains unresolved. Host loopback and resolved
  stub UDP/TCP checks then passed without needing to restart resolved manually.
- Eir and ymir passed LAN UDP/TCP filtering (ads/porn/fakenews/gambling A and AAAA), Google/Facebook
  Fake-IP, Baidu real-IP and native Tailnet-name checks. Eir's routed external `1.1.1.1:53` probes
  were filtered. Both clients returned Google 204 and Baidu 200 over their `.2` gateway. Ymir's
  generic resolved lookup presented the blocked name as no address records; direct wire probes
  confirmed the configured null-IP answers over both protocols.
- Both panels passed external HTTPS checks, with unauthenticated APIs rejected as 401. Private
  authenticated AdGuard checks passed locally and through Tailnet HTTPS, with 166,905 rules under
  filter ID 2 and unchanged upstream/cache/fallback settings.
- Private comparisons confirmed identical proxy JSON, all manual selectors, mode, native/embedded
  identities and native daemon PID. Serve 443 and 8443 mappings were preserved, with no Funnel.
  Native ExitDNS returned public non-Fake-IP A answers for Google/Baidu. Google AAAA returned
  NOERROR with no answers; no IPv6 exit-connectivity claim is made. Table 52 and priority 5100/table
  2023 remained, with no physical IPv6 default route.
- Permanent retention at `2026-11-25T02:27:05Z` created generation 23 without restarting the three
  daemons again. Verification passed, the rollback timer was cancelled, and no failed units
  remained. The system profile protects the closure; private snapshots and the temporary candidate
  GC root were removed afterward.

No second reboot, proxy-failure injection, actual gameplay, cellular exit acceptance or subscription
refresh repair was performed. Generation 22 remains the filtered rollback baseline:
`/nix/store/n9vjpkwpj4a136xv2rsc2l0vbz0y33bn-nixos-system-heimdall-26.11.20261111.d4f25a3`. Records:
`/private/tmp/heimdall-readiness/`, `/run/heimdall-readiness-deploy/` and
`/var/tmp/heimdall-readiness-{activate,retain}.log`.

## Post-restart check — generation 22

Heimdall booted at `2026-11-25T01:59:06Z`. The booted and running closures both match generation 22;
this did not activate the later module extraction. LAN address `.2/24`, default gateway `.1` and
`enp2s0` returned, with a 2500 Mb/s full-duplex physical link. This observes the host link, not the
switch's internal configuration. Networkd, resolved, native Tailscale, sing-box, AdGuard and the
AdGuard Serve unit recovered without manual starts.

The sing-box Serve unit failed at 01:59:15 with `unexpected state: NoState`; only HTTPS 8443 was
published. After confirming native tailscaled was Running, starting just
`sing-box-tailnet-webui.service` restored 443 without changing 8443. Sing-box, tailscaled and
AdGuard PIDs stayed unchanged during this recovery; no failed units remained. The shared-unit
readiness/retry fix and mocked tests were prepared but not yet deployed at this checkpoint (see
subsequent generation 23 above). This is a successful gateway/DNS restart with a manually recovered
management panel, not complete unattended startup acceptance.

Post-recovery checks:

- Host resolved returned domestic real addresses, Google Fake-IP and null-IP ad blocking.
- Eir's public route used `.2` through `en0`. LAN UDP/TCP queries retained Google Fake-IP, Baidu
  real-IP and Heimdall's native Tailnet address. Ads/porn/fakenews/gambling samples were blocked for
  A and AAAA. Routed queries addressed to `1.1.1.1:53` were also filtered over UDP/TCP.
- Host HTTPS returned Google 204 and Baidu 200; eir's direct LAN Google probe returned 204. Tailnet
  sing-box UI returned 200, and AdGuard's login page returned 200 after following its redirect. Both
  unauthenticated API probes returned 401; authenticated API access was not retested.
- Native table 52 and LAN priority 5100/table 2023 remained, and no IPv6 default route was present.
- The subscription timer was scheduled, but its service had not run in this boot. Its empty start
  timestamp means `Result=success` is not evidence of an actual refresh. No refresh/core restart was
  forced during this check.

Default regressions passed for the prepared readiness fix. No fault injection, second reboot, actual
gameplay, native ExitDNS/exit forwarding or full filter false-positive acceptance was performed. A
separate guarded deployment and subsequent startup test remain necessary.

## Expanded subscription — generation 22

- Regressions, build and dry activation passed. A separate ten-minute generation-21 rollback was
  armed before switching; the new seed loaded **166,905 rules** under ID 2. Exactly one filter is
  enabled.
- Eir and ymir UDP/TCP tests blocked ads/porn plus representative `infowars.com` and `bet365.com`
  A/AAAA queries. Facebook and Google retained Fake-IP answers, Baidu real addresses, and the native
  Heimdall name its Tailnet address. Eir's external `1.1.1.1:53` queries were also filtered.
- The bounded probe retried initial embedded-Tailnet NXDOMAIN until ready. The host resolved stub
  passed both protocols without requiring another restart. Google 204/Baidu 200 and UI 200 passed;
  authenticated API and unauthorized 401 checks passed. Proxy JSON, selectors, mode and identities
  remained unchanged. No claim of full social-site functionality or news-content classification is
  made.
- Permanent retention preserved daemon PIDs, cancelled rollback and left no failed units. No reboot
  or actual gameplay test was performed. The previous porn-only generation 21 remains available:
  `/nix/store/2y2lkhb021y33i0l7h5w2plzp20jmn0g-nixos-system-heimdall-26.11.20261111.d4f25a3`.
- Records: `/private/tmp/heimdall-adguard-expanded/` and `/run/heimdall-adguard-expanded-deploy/`.

## Initial deployment record — generation 21

- Default regressions, credential/seed helper tests, Nix assertions, the remote toplevel build and
  real nftables syntax check passed. SOPS decryption was tested privately using the host's
  SSH-derived age identity. No plaintext credential/hash was put into the store, argv or agent
  output.
- An isolated loopback-only AGH instance validated authentication, the pinned seed and real UDP/TCP
  responses before changing production. This caught that AGH 0.107.79 needs `cache_enabled=false`,
  not merely `cache_size=0`; declarations/tests were corrected and rebuilt. The staging instance and
  its private runtime files were removed before deployment.
- Scheduled `fast-nix-gc` collected the first unrooted candidate before activation. It was rebuilt
  and protected with `/run/heimdall-adguard-candidate`; retain a GC root for future prepared
  candidates.
- A ten-minute independent rollback to generation 20 was armed before activation. The first
  immediate Tailnet DNS probe hit NXDOMAIN while the embedded endpoint was becoming ready; it passed
  on retry without changing policy or re-enrolling. Separately, the resolved UDP stub needed the
  explicit restart described above. Both host stub protocols then passed. These are readiness/reload
  findings, not complete cold-boot acceptance or an upstream root-cause diagnosis.
- From eir and ymir, UDP/TCP queries to `.2` blocked `doubleclick.net` and `pornhub.com` for A and
  AAAA; Google retained Fake-IP, Baidu real-IP and the Heimdall FQDN Tailnet answers. Eir queries
  addressed to external `1.1.1.1:53` gave the same filtered results and incremented the owned NAT
  counter.
- Host and eir HTTPS returned Google 204/Baidu 200. Both Tailnet panels returned 200;
  unauthenticated AdGuard and sing-box control APIs returned 401. Authenticated AdGuard API access
  also passed through Tailnet HTTPS 8443. Port 3000 listens only on loopback; 8443 listens only on
  native Tailnet addresses.
- The loaded list has **157,986 rules**. A manual subscription refresh succeeded (`updated=0`, list
  unchanged), with protection still enabled. This verifies the update path, not a full day of
  timers.
- Private before/after checks found identical proxy JSON, all manual selector choices and Clash
  mode, unchanged native/embedded identities and native tailscaled PID. Native PeerAPI ExitDNS
  returned non-Fake-IP public Google/Baidu answers; this is not foreign-site or cellular-exit
  acceptance.
- Permanent retention did not restart sing-box, AdGuard or tailscaled again. The rollback timer was
  cancelled, and no failed system units remained. No reboot, failure-injection, actual gameplay or
  comprehensive filter false-positive acceptance was performed.

Generation 20 is the full-LAN, unfiltered-DNS rollback baseline:
`/nix/store/wjhgy3r5xslxh9jska41gf8vlfvdf0i8-nixos-system-heimdall-26.11.20261111.d4f25a3`. Do not
confuse it with generation 19's two-client admission.

Records: `/private/tmp/heimdall-adguard/` on eir; `/run/heimdall-adguard-deploy/` and
`/var/tmp/heimdall-adguard-{activate,retain}.log` on Heimdall. The initial activation wrapper's
failed state was cleared only after the readiness/stub issues were explicitly diagnosed and checks
passed. Private before/after snapshots and the temporary candidate GC root were removed after
retention; the system profile now protects the closure. The operator's trusted `ssh heimdall` alias
was also checked for password retrieval; the password itself was never displayed by the agent.
