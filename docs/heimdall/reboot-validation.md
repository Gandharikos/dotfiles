# Heimdall: restart acceptance and LAN readiness

## Scope and current evidence

Two separately approved normal OS reboots are recorded here. Generation 23 booted at
`2026-11-25T17:45:43Z`: the proxy panel recovered automatically, but AdGuard needed one retry
because its LAN address was not ready. After the scoped fix, **generation 24 booted at
`2026-11-25T18:42:11Z` and recovered without manual starts or automatic restarts of the five checked
services**. Its booted, running and profile paths all match the retained generation-24 closure. This
establishes the bounded normal-restart result, not AC-loss power-on or arbitrary outage recovery.

Subscription work and the new-node deployment remain paused. Do not rebuild from the current
checkout as part of this test: its encrypted node seed is newer than the retained configuration.

## Generation 24 restart — first-attempt service recovery

The operator approved the maintenance window. A new root-only persistent baseline captured proxy
configuration hash, manual selectors/mode and identity metadata; no plaintext configuration or
credentials were saved. Generation 24's default and generation 23's fallback files were verified
before one normal `systemctl reboot`. No rebuild, subscription refresh, node import or manual
service start/restart was performed.

- Boot ID changed. Booted/runtime/profile paths match
  `/nix/store/k1h90jygqskrf9nwska8ym5d061vr53j-nixos-system-heimdall-26.11.20261111.d4f25a3`. SSH
  initially timed out while the machine restarted; on its first successful poll all seven queried
  network/DNS/proxy/panel services were active, with no failed units.
- Native tailscaled became active at 18:42:19 and sing-box at 18:42:20. AdGuard's native IPv4 gate
  ran from 18:42:20 to 18:42:23, exited successfully, then allowed credential/settings preparation
  and AdGuard startup. AdGuard and both panel units were active at 18:42:23.
- AdGuard, sing-box, native tailscaled and both panel units all had `NRestarts=0`, still zero at
  final inspection. The current-boot journals contained no recurrence of AdGuard's
  `cannot assign requested address` or the proxy panel's `NoState` error. No operator recovery was
  needed. This tests the ordinary startup case; delayed-address and timeout paths are covered by the
  separate isolated VM fixture.
- Host resolved stub and eir/ymir LAN UDP/TCP tests passed for ads/porn/fakenews/gambling A/AAAA
  blocking, Google/Facebook Fake-IP, Baidu real-IP and native Tailnet-name answers. Eir's routed
  external `1.1.1.1:53` queries were filtered over both protocols. Eir and ymir returned Google 204
  and Baidu 200; ymir retained its DHCP gateway `.2`.
- Both external panel pages returned 200 and unauthenticated APIs returned 401. Private
  authenticated AdGuard checks passed locally and over Tailnet HTTPS, with 166,905 rules, the same
  upstream/cache settings and preserved 443/8443 Serve mappings without Funnel.
- Proxy JSON, every manual selector, mode and native/embedded identities matched the pre-restart
  snapshot. PIDs were deliberately not compared across reboot. Native ExitDNS returned public
  non-Fake-IP A answers for Google/Baidu. Flint remained the main IPv4 gateway; native table 52 and
  LAN priority 5100/table 2023 remained, with no IPv6 default route.

Private snapshots were removed after successful comparison. Records/helpers remain under
`/private/tmp/heimdall-reboot24/` and `/var/lib/heimdall-reboot24-validation/`. The earliest DNS
readiness interval was not continuously sampled, so this does not close the separate transient
embedded-Tailnet NXDOMAIN finding. No proxy-stop fault injection, AC-loss power-on, actual gameplay,
cellular exit or comprehensive filtering acceptance was performed. Subscription 403 and the newer
node deployment remain paused, not repaired by this restart.

## Earlier generation-23 preparation

The earlier read-only preparation confirmed:

- Runtime, system profile and the systemd-boot default all select generation 23:
  `/nix/store/lixx25fa1l703zi057sgrx3f4aqgarab-nixos-system-heimdall-26.11.20261111.d4f25a3`.
- Generation 22's fallback entry and generation 23's default entry both reference the expected
  closures; their executable init, kernel and initrd files were present.
- The last actual boot, at `2026-11-25T01:59:06Z`, still used generation 22. Generation 23's panel
  readiness fix has been activated, but has not yet been exercised through a host restart.
- Networkd, resolved, SOPS, tailscaled, sing-box, AdGuard, both panel units and the LAN-to-Tailnet
  routing helper were active and enabled. There were no failed units or active rollback timers.
- The sing-box panel unit had `Restart=on-failure`, a 30-second retry delay and a 120-second startup
  timeout. It had required no automatic retries since activation.
- `enp2s0` retained `.2/24`, default gateway `.1` and a 2500 Mb/s full-duplex link. There was no
  IPv6 default route. LAN UDP/TCP DNS filtering and Fake-IP/real-IP/Tailnet-name probes passed;
  Google returned 204 and both Tailnet panels returned 200.
- `/run/heimdall-node-seed-candidate` points to a built but unactivated node-update candidate. It is
  not the system profile or boot default; leave it out of this acceptance test.

These observations do not prove unattended recovery or identify the switch's internal configuration.
See [the deployed change and generation-22 startup failure](adguardhome.md) for prior evidence.

## Generation 23 restart — 2026-11-25

- A root-only persistent snapshot was captured before reboot (directory 0700, files 0600),
  containing configuration hashes, selector/mode and identity metadata, not plaintext configuration
  or credentials. The generation-23 runtime/profile and generation-22/23 boot entries were
  rechecked. A single approved `systemctl reboot` was scheduled through systemd. No rebuild, node
  import, fallback switch, DHCP/IPv6 change or manual service restart was performed.
- Boot ID changed, and booted/runtime/profile paths all match generation 23. Initial SSH attempts
  timed out before the host returned. The first successful poll still saw AdGuard and the proxy
  panel activating; observation continued without intervention.
- The proxy panel started at 17:45:52 and finished at 17:46:00, with success and `NRestarts=0`. It
  recovered without the earlier `NoState` failure or a manual start. Native tailscaled also reported
  zero automatic restarts.
- AdGuard's first process failed at 17:45:53 because binding `192.168.8.2:53` returned
  `cannot assign requested address`. Its existing restart policy retried at 17:46:03; the service
  and its dependent Serve handler were active at 17:46:04. `NRestarts=1` remained stable during the
  later checks. This exposes a separate LAN-address readiness race, not a credential failure. A
  targeted fix is still needed; changing the global network manager or opening wildcard DNS
  listeners is not an appropriate workaround.
- Host resolved stub and eir/ymir LAN UDP/TCP DNS checks passed for ads/porn/fakenews/gambling
  A/AAAA blocking, Google/Facebook Fake-IP, Baidu real-IP and native Tailnet names. Eir's external
  `1.1.1.1:53` queries were intercepted over both protocols. Eir and ymir returned Google 204 and
  Baidu 200; ymir retained DHCP gateway `.2` on `wlan0`.
- Both external panel pages returned 200, and unauthenticated APIs returned 401. Private
  authenticated AdGuard API checks passed with 166,905 rules under ID 2, unchanged upstream/cache
  settings and preserved Serve 443/8443 handlers without Funnel.
- Canonical proxy JSON, all manual selectors, mode and native/embedded identities matched the
  pre-restart snapshot. PIDs were deliberately not compared across reboot. Native PeerAPI ExitDNS
  returned public non-Fake-IP A answers for Google and Baidu.
- The physical link returned at 2500 Mb/s full duplex, with gateway `.1`, native table 52 and LAN
  priority 5100/table 2023. No IPv6 default route or failed units remained at the final check.

The earliest embedded-Tailnet DNS readiness interval was not continuously sampled, so these later
successful lookups do not close the separate transient-NXDOMAIN finding. No AC-loss power-on test,
proxy-stop fault injection, delayed-network simulation, actual gameplay or cellular exit test was
performed. Private snapshots were removed after comparison; the sanitized record and verification
scripts remain under `/var/lib/heimdall-reboot-validation/`, with local helpers under
`/private/tmp/heimdall-reboot-check/`.

## LAN-address readiness fix — generation 24

The host's AdGuard unit now declares a service-local `ExecStartPre` gate using the existing systemd
binary:

```text
systemd-networkd-wait-online --interface=enp2s0:routable --ipv4 --dns=no --timeout=60
```

It wants/orders after networkd and runs this gate before the upstream configuration merge and
credential/seed preparation. Networkd must finish configuring this interface with routable IPv4,
including its IPv4 duplicate-address detection. The management network declares only the static
`192.168.8.2/24` address, with DHCP disabled; evaluation tests pin that assumption. If addresses or
interface ownership change, revisit this gate rather than assuming any routable IPv4 is sufficient.

Global wait-online remains disabled. No DNS query or Internet reachability is required, avoiding a
resolver startup dependency loop. No wildcard listener, firewall relaxation, route change, new
helper script or global network-manager adjustment is introduced. The wait is limited to 60 seconds;
AdGuard retains its existing 90-second startup budget and `Restart=always`/10-second retry policy.
This is a startup gate, not a guarantee against later address removal or cable failure.

Pre-deployment validation:

- Default regressions and host assertions passed, including first-`ExecStartPre` ordering, retained
  restart policy and disabled/DAE isolation.
- A same-source before/after evaluation found unchanged DNS/filter settings, credentials
  preparation, LAN network configuration, firewall/NAT, sing-box/tailscaled/resolved units and
  AdGuard's Serve unit. Only the AdGuard unit's gate and networkd dependencies changed. This
  compares the code edit, not the current checkout against the older deployed generation.
- `tests/test-adguard-lan-ready.nix` passed in an isolated Linux KVM VM. It uses the actual declared
  gate and inherits AdGuard's DynamicUser, address-family, syscall and filesystem restrictions.
  Cases cover a missing interface timing out, routable IPv6 alone not satisfying the IPv4 gate,
  delayed LAN configuration allowing a real bind to `.2`, and timeout/retry recovery when the
  interface arrives later. Timeout cases use a shortened two-second budget; the delayed-success case
  uses the production 60-second command. No production interface or secret is imported.

Run the VM test on a Linux builder with KVM:

```sh
nix --extra-experimental-features 'nix-command flakes pipe-operators' build \
  --impure --no-link --file tests/test-adguard-lan-ready.nix
```

The VM build did not restart production services. The existing subscription timer independently ran
and failed at 18:04 UTC; no manual refresh or failure-state reset was performed during testing.

### Scoped deployment and retention

After approval, the retained source `/nix/store/ang0gc4gh66scllxwyhx7pzbzfz2fn0r-source` reproduced
the generation-23 toplevel exactly. An `extendModules` override added only the networkd dependencies
and first `ExecStartPre` gate. Evaluation proved that **only `adguardhome.service` changed**, with
all secret declarations, DNS/filter settings, firewall tables and other systemd units preserved.
This deliberately excludes the current checkout's newer encrypted nodes/URL and unrelated changes.

The remote build and dry activation passed. An independent systemd dry-activation check verified the
recovery execution path, then a ten-minute generation-23 rollback was armed. Test activation at
18:31:36 UTC stopped/started only AdGuard; its dependent Serve handler recovered. The native
wait-online command exited successfully before the existing preparation script. AdGuard reported
success with zero automatic retries. LAN IPv4 was already present, so this activation is not a
cold-start acceptance test.

Host stub and eir/ymir LAN UDP/TCP DNS checks passed: ads/porn/fakenews/gambling A/AAAA blocking,
Google/Facebook Fake-IP, Baidu real addresses and Tailnet names. Eir's external port-53 requests
were intercepted. Eir HTTPS returned Google 204 and Baidu 200, both panels returned 200, and
unauthenticated APIs returned 401. Private authenticated AdGuard checks passed with 166,905 rules.
Native ExitDNS returned public non-Fake-IP A answers for Google/Baidu.

Private comparisons confirmed identical proxy JSON, all manual selectors, mode, both identities,
Serve mappings and sing-box/native tailscaled PIDs. Neither proxy core nor native Tailscale was
restarted. Permanent retention created **generation 24** at `2026-11-25T18:32:58Z`, without another
daemon restart:

`/nix/store/k1h90jygqskrf9nwska8ym5d061vr53j-nixos-system-heimdall-26.11.20261111.d4f25a3`.

At retention, runtime/profile/boot default matched generation 24 while the last actual boot was
still generation 23; the subsequent generation-24 restart is recorded above. After verification,
rollback was cancelled and private snapshots/temporary candidate GC root were removed. No failed
units remained, but the subscription job still had its old 18:04 timestamp and `ExecMainStatus=1`
despite `Result=success` after activation. This is **not** evidence that refresh was repaired. No
new nodes/URL, routing change, full reboot or subscription refresh was deployed.

Records: `/private/tmp/heimdall-adguard-lan-ready/`, its scoped expression also copied to
`/var/tmp/heimdall-adguard-lan-ready-upload/scoped.nix`, `/run/heimdall-adguard-lan-ready-deploy/`,
and `/var/tmp/heimdall-adguard-lan-ready-{activate,retain}.log`.

Do **not** blindly switch the current checkout while the node update remains paused. Production
restart acceptance of generation 24's new gate subsequently passed as recorded above; wider outage
and power-loss scenarios remain unverified.

## Checklist for a separately approved restart

1. Confirm the user is present, accepts several minutes of LAN Internet/DNS interruption and can
   reach the machine with a display/keyboard if SSH fails. Keep a cellular channel for coordination.
2. Verify the exact running/profile/default paths again. Do not run `just switch`, deploy the node
   candidate, change DHCP/IPv6 or refresh subscriptions as part of this test.
3. For a generation-24 test, verify generation 23's fallback entry and closure. It preserves
   full-LAN filtering and the proxy panel fix, but AdGuard may need its existing automatic retry.
   Generation 22 was the fallback for the earlier generation-23 test. Do not select generation 19 or
   an earlier two-client policy as a casual fallback.
4. Capture a private pre-restart snapshot outside `/run`, root-owned with directory mode 0700 and
   file mode 0600: canonical proxy-config hash, current manual selectors/mode and native/embedded
   identity identifiers. Do not save plaintext configuration or credentials, or print snapshot
   values. Record the boot ID and the selected generation separately.
5. Verify LAN SSH by literal address or the trusted `heimdall` alias, independently of DNS/proxy
   availability. Native Tailnet SSH last requested interactive reauthentication; do not count it as
   an established recovery channel until that is completed and tested.
6. Obtain explicit restart approval, then issue one normal OS reboot. This tests startup/service
   ordering, not AC-loss automatic power-on. Do not combine it with a forced power cut.

The transient `systemd-run --on-active` rollback timers used for prior switches do **not** provide
cross-reboot recovery. None is armed now. Do not rely on an in-memory timer to fix an unbootable
host. This plan relies on verified LAN access plus an operator-attended local boot-menu fallback; if
local recovery is unavailable, postpone the restart or design and test persistent recovery first.

## Post-restart acceptance

Observe for up to five minutes without manually starting units, so the readiness fix is actually
tested. Record any DNS readiness gap rather than treating a successful retry as zero interruption.

- A new boot ID, with booted/runtime/profile paths all matching the approved target (generation 24
  and generation 23 for the respective tests recorded above).
- The original LAN address, Flint default route and physical link; no new physical IPv6 default.
- All required services active, no failed units, and both Serve handlers recovered automatically.
  Inspect the proxy panel's current-boot journal and retry count. Bounded automatic recovery is
  acceptable for the proxy panel; an operator start/restart means unattended startup acceptance
  failed. For the new AdGuard gate, normal LAN startup should complete without an AdGuard automatic
  restart; record any timeout/retry separately rather than claiming error-free recovery.
- Host DNS via `127.0.0.53` and LAN DNS via `.2`, using both UDP and TCP. Check ad/porn/fakenews/
  gambling A/AAAA blocking, domestic real addresses, foreign Fake-IP and native Tailnet names.
- Routed external port-53 interception, domestic/foreign HTTPS and both Tailnet panels from another
  machine. Confirm unauthenticated API rejection and privately check authenticated access.
- Native table 52 and LAN priority 5100/table 2023; check native ExitDNS separately for non-Fake-IP
  A answers. Do not confuse this with cellular exit or physical IPv6 connectivity acceptance.
- Compare proxy-config hash, manual selectors/mode and both identities with the private baseline.
  Daemon PIDs are expected to change across reboot; do not assert PID equality.

Do not stop the proxy for fault injection during this test. Actual gameplay, long-term filter false
positives and delayed-network recovery remain separate acceptance tasks.

## Recovery and recording

If LAN SSH works but a panel fails, capture its current-boot journal first, then recover only the
owned panel unit as needed. Do not reset all Tailscale Serve mappings, re-enroll identities or turn
off filtering as an improvised workaround. A manual recovery must be recorded as such.

If the host cannot boot or LAN management remains unavailable, use the local console and choose the
verified fallback entry (generation 23 for a generation-24 test). Selecting an older entry does not
by itself change the persistent system profile/default: verify the booted path and coordinate a
deliberate retention/rollback once access is restored. Preserve state directories and all encrypted
credentials. Network-client DHCP settings should remain unchanged.

After checks, document actual results, exceptions and any recovery actions. Remove the private
snapshot only after successful comparison or deliberate recovery. The original preparation phase
made no runtime changes; the separately approved execution and its exception are recorded above.
