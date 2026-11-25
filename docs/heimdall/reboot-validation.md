# Heimdall: generation 23 restart acceptance

## Scope and current evidence

The user authorized one normal OS reboot after the preparation below. Generation 23 booted at
`2026-11-25T17:45:43Z`; gateway/DNS and both panels recovered without manual service starts. The
proxy panel readiness fix passed this startup check. **AdGuard required one automatic restart due to
its LAN address not being ready**, so this is not a clean, error-free startup result. See the
execution record below.

Subscription work and the new-node deployment remain paused. Do not rebuild from the current
checkout as part of this test: its encrypted node seed is newer than the retained configuration.

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

## Execution record — 2026-11-25

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

## Checklist for a separately approved restart

1. Confirm the user is present, accepts several minutes of LAN Internet/DNS interruption and can
   reach the machine with a display/keyboard if SSH fails. Keep a cellular channel for coordination.
2. Verify the exact running/profile/default paths again. Do not run `just switch`, deploy the node
   candidate, change DHCP/IPv6 or refresh subscriptions as part of this test.
3. Verify a generation-22 boot entry and its closure remain available. Generation 22 preserves
   full-LAN admission and filtering, but its proxy panel can require manual recovery. Do not select
   generation 19 or an earlier two-client policy as a casual fallback.
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

- A new boot ID, with booted/runtime/profile paths all matching generation 23.
- The original LAN address, Flint default route and physical link; no new physical IPv6 default.
- All required services active, no failed units, and both Serve handlers recovered automatically.
  Inspect the proxy panel's current-boot journal and retry count. Bounded automatic recovery is
  acceptable; an operator start/restart means unattended startup acceptance failed.
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
verified generation-22 entry. Selecting an older entry does not by itself change the persistent
system profile/default: verify the booted path and coordinate a deliberate retention/rollback once
access is restored. Preserve state directories and all encrypted credentials. Network-client DHCP
settings should remain unchanged.

After checks, document actual results, exceptions and any recovery actions. Remove the private
snapshot only after successful comparison or deliberate recovery. The original preparation phase
made no runtime changes; the separately approved execution and its exception are recorded above.
