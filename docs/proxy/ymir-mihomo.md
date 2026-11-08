# ymir: retained Mihomo profile

The declared backend is now sing-box; see [the sing-box deployment](ymir-sing-box.md). This page
describes the retained Mihomo alternative, enabled by setting
`dot.networking.proxy.backend = "mihomo"`.

## Status before activation

The replacement subscription returned HTTP 200 through the existing Mullvad exit, with 32 Trojan
nodes. A request bound directly to `wlan0` still returned HTTP 403 (Cloudflare). Both the URL and a
nodes-only bootstrap snapshot are encrypted in `secrets/services/proxy.yml`. The service seeds its
cache before startup, so it does not require a successful first subscription download. Online
subscription updates use **DIRECT**. The local 403 is not treated as a universal restriction: other
devices on the same Wi-Fi can download directly. Successful parsing does not prove node health. With
an empty provider, `Proxy` defaults to `Auto`, which selects `REJECT`, not a direct fallback.

The retained Mihomo profile was built but not activated. Sing-box is now active, with the system
Mullvad exit node cleared; see [the sing-box deployment](ymir-sing-box.md) for current validation
and pending items.

## Responsibilities

| Identity      | Purpose                                                                                                             |
| ------------- | ------------------------------------------------------------------------------------------------------------------- |
| `ymir`        | System `tailscaled`; native Tailnet connections, SSH/Taildrop; no exit node, accepted subnet routes or DNS takeover |
| `ymir-mihomo` | Independent embedded `tsnet` identity for explicit proxy requests to Tailnet                                        |
| `ymir-rex`    | Existing Rex identity; Rex transport matches a direct process rule                                                  |

```text
Native Tailnet / SSH / Taildrop -> system Tailscale
Other applications -> Mihomo TUN -> domestic/LAN: DIRECT
                                -> other Internet: subscription
Explicit SOCKS/HTTP -> Mihomo rules -> Tailnet: embedded Tailscale
Remote peers -> system tailscaled -> local SSH/Taildrop
Remote peers -> Rex's embedded Tailscale -> Rex
```

Mihomo runs as a headless system service. MetaCubeXD is served locally by Mihomo, not fetched from
an external dashboard site. The mixed proxy (`127.0.0.1:7890`) and controller/WebUI
(`127.0.0.1:9090`) are loopback-only; API access requires the controller secret.

## WebUI and node selection

After activation, open **http://127.0.0.1:9090/ui/** on ymir. In MetaCubeXD, add the backend
`http://127.0.0.1:9090` and enter the token from `/run/secrets/mihomo_controller_secret`
(root-readable). Do not put the token in a URL, screenshot, or Git file. The static dashboard can
load without a token, but it cannot control Mihomo without API authentication.

In the **Proxy** group:

- Select **Auto** for automatic latency-based node selection (the default).
- Select an individual subscription node to pin it manually.
- Select **Auto** again to return to automatic selection.

Selections persist across restarts through `profile.store-selected`. The **Auto** group tests nodes
every 300 seconds with a 50 ms tolerance. It uses `REJECT` when no subscription nodes are available.
Internet traffic and the embedded Tailscale transport both follow the selected **Proxy** entry;
changing it can interrupt existing connections. System `ymir` and Rex retain their separate paths.

No firewall port is opened for the dashboard. With `profile.tailnet.webUI.enable = true`, the shared
profile also supports Tailnet HTTPS for Mihomo. After selecting and activating this backend,
`mihomo-tailnet-webui.service` forwards the system identity's HTTPS handler to the loopback
controller. On ymir, use `https://ymir.tail2cfd9e.ts.net/ui/` with backend
`https://ymir.tail2cfd9e.ts.net` and the Mihomo controller token. Funnel remains disabled. The
handler is shared with the alternative sing-box service, not a second simultaneous mapping. This
support is prepared; the running backend on ymir is still sing-box.

SSH forwarding remains an alternative to Tailnet Serve; do not expose the controller on `0.0.0.0`:

```sh
ssh -N -L 19090:127.0.0.1:9090 johnson@ymir
```

Then open `http://127.0.0.1:19090/ui/` and use `http://127.0.0.1:19090` as the backend, with the
same token.

## Configuration and secrets

- `config/mihomo/config.yaml`: shared base, with listeners, DNS, TUN, subscription/Tailnet settings
  and host/credential placeholders; selected by `profile.mihomo.template`.
- `config/mihomo/policy.yaml`: proxy groups, rule providers and ordered routing rules; selected by
  `profile.mihomo.policy`. It is appended as part of the same YAML mapping, without overriding base
  keys.
- `modules/nixos/networking/proxy/mihomo-profile.nix`: reusable SOPS rendering and provider cache;
  host parameters live in `hosts/ymir/config.nix`, with shared Tailnet options and Serve in
  `modules/nixos/networking/proxy/tailnet-profile.nix`.
- `secrets/services/proxy.yml`: encrypted subscription URL, nodes-only bootstrap snapshot and
  controller token. Edit with SOPS.
- `/run/secrets/rendered/proxy-mihomo.yaml`: root-only runtime configuration, passed to the dynamic
  service user via systemd `LoadCredential`.
- `/var/lib/private/mihomo`: persistent provider/rule caches and the embedded Tailscale state. The
  host already preserves `/var/lib`. Do not copy the system tailscaled or Rex state here.

The subscription supplies **nodes only** through a provider. Its groups, DNS, controller and rules
do not replace the local configuration. Providers refresh daily. The bootstrap snapshot is passed as
a separate systemd credential and copied to the private provider cache on first startup. A hash
marker preserves newer online updates across restarts; changing the encrypted snapshot replaces the
cache on the next start. Neither node passwords nor the subscription URL enter the Nix store in
plaintext. Nix substitutes `sops.placeholder` markers into the public template; sops-nix fills in
the secrets at activation/boot. The base/policy split preserves the original policy and cache paths.
Keep the encrypted snapshot current when rotating subscription credentials.

Subscription refreshes use **DIRECT**. A cached provider loads before its online refresh, so a
failed initial download does not remove the bootstrap nodes. If a direct refresh fails, the cache
remains usable; investigate the host-specific download failure and retry in the WebUI. CN rule
providers are still fetched directly; their endpoints must be reachable, or their caches must be
provisioned before activation.

`systemd-resolved` forwards to Mihomo on `127.0.0.1:1053`. Tailnet names under `tail2cfd9e.ts.net`
use the embedded resolver. Node/bootstrap DNS and Tailscale control-plane DNS have direct upstreams
to avoid depending on the subscription. There is no general DNS fallback when Mihomo is down;
stopping only Mihomo is not a complete rollback.

## Routing invariants

Tailscaled's transport-mark rules at priorities 5210–5250 and its table-52 lookup at 5270 remain
untouched. Native Tailnet connections use system Tailscale before Mihomo's policy rules at 9000. The
TUN template excludes both Tailnet IP ranges and incoming `tailscale0` traffic; TCP auto-redirect
remains disabled. Explicit mixed-proxy requests can still select the embedded Tailnet outbound.

The former 5260/5261 overrides and their routing service are removed. Activation must stop the old
service so its `ExecStop` cleans up the owned rules. No extra firewall exception is installed. These
table numbers and priorities are implementation details: rerun tests after upgrading
Tailscale/Mihomo. See the
[shared identity boundaries](shared-profile.md#system-proxy-and-rex-identities).

## Validation and activation

```sh
python3 -m unittest discover -s tests -p 'test_mihomo_profile.py' -v
bash tests/test-tailnet-routing.sh
nix build --no-link .#nixosConfigurations.ymir.config.system.build.toplevel
seed_program=$(nix eval --raw --apply builtins.head .#nixosConfigurations.ymir.config.systemd.services.mihomo.serviceConfig.ExecStartPre)
bash tests/test-mihomo-provider-seed.sh "$seed_program"
```

The routing test uses an unprivileged network namespace and dummy interfaces. It covers IPv4/IPv6
native connections, system-identity replies, transport-mark bypass, public TUN traffic, LAN/local
access, removal of the legacy destination override and an absent proxy table. It models kernel
policy lookup, not a running core. Historical Mihomo 1.19.33 isolated tests used the previous
routing layout; they do not validate this new layout. Neither proves live authentication, ACL
permissions, NAT traversal or provider health.

The seed test checks cache permissions, preservation of online updates, snapshot rotation and
recovery from a missing/empty cache. An isolated Mihomo startup also loaded all 32 downloaded nodes
from the seeded HTTP-provider cache without Internet access.

Activate only after reviewing the change, from the local console or with a separate recovery
session. Check node health and subscription refresh in the WebUI, then trigger an embedded Tailnet
connection, for example:

```sh
curl --proxy http://127.0.0.1:7890 --connect-timeout 5 --max-time 10 http://100.80.170.40/
journalctl -u mihomo -n 80
```

This request is only a login trigger; the peer need not serve HTTP. On first use, follow the
interactive Tailscale login URL in the journal to authorize `ymir-mihomo`. Initial requests may time
out. Do not share unredacted logs: login links and provider errors may contain credentials.

Verify from another device that SSH to the original `ymir` address and Rex access still work. Verify
native Tailnet connections keep the system identity, explicit proxy requests use the embedded
identity, and public/Chinese/LAN traffic follows the intended rules. The existing system
`tailscale status` command does not describe the embedded identity; check it in the Tailnet admin
console and Mihomo logs.

For rollback, switch to the previous NixOS generation (for example `just rollback`) rather than only
stopping Mihomo. This restores the previous DNS and routing configuration, including its previous
exit-node selection. No existing Tailscale identity/state is deleted by this change.
