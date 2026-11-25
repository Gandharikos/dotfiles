# Heimdall: AdGuard Home before sing-box DNS

## Scope and ownership

Deployed with ads/tracking plus the requested **fakenews, gambling and porn** extensions; social is
not selected. **Generation 22** was retained at `2026-11-25T01:17:12Z`. Runtime and the default
profile match:
`/nix/store/n9vjpkwpj4a136xv2rsc2l0vbz0y33bn-nixos-system-heimdall-26.11.20261111.d4f25a3`.
Deployment evidence is recorded below; declarations alone are not proof of activation.

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
