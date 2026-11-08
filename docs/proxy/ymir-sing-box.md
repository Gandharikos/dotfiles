# ymir: sing-box + embedded Tailscale

The active backend is now `sing-box`. The Mihomo profile remains available by changing
`dot.networking.proxy.backend` back to `"mihomo"`. Never start both TUN/controller services
together. No dae or Clash desktop client is used.

## Live validation (2026-11-08)

- Full current-flake ymir build, 17 subscription/policy tests (including real-core rule matching),
  routing tests, and core validation of all 32 nodes passed.
- The system switch is complete. Four AI and 20 service selectors are live. Auto has 26 eligible
  nodes; all 32 nodes remain available manually. The existing manual Proxy selection was preserved.
- Domestic/public HTTPS, IPv6, DNS, Nix cache access, Tailnet HTTPS WebUI and authenticated
  controller access passed. Unauthenticated API requests return 401; the controller still listens
  only on loopback. Funnel is disabled.
- System Tailscale has no exit node. Inbound SSH and the existing Rex process/session remained
  available. The automatic rollback timer was cancelled after final verification.
- Embedded Tailnet outbounds were not revalidated during this switch. The `ymir-singbox` identity
  needs its own authorization, separate from system `ymir` and the HTTPS panel.
- The last tested direct subscription refresh returned HTTP 403. The valid 32-node snapshot remains
  active; a refresh failure does not replace it or stop sing-box.

Initial activation exposed incorrect CN rule-set paths; they now use `geo/geosite/cn.srs` and
`geo/geoip/cn.srs`. Sing-box also explicitly requires `tailscaled-set.service` before starting, so
switching clears a previously selected exit node without restarting the system Tailscale identity.

## Identities and routing

```text
Applications -> sing-box TUN -> domestic/LAN: direct
                            -> Internet: Proxy -> Auto or a selected subscription node
                            -> Tailnet: ymir-singbox endpoint
Remote peers -> system ymir identity -> SSH/Taildrop
Remote peers -> ymir-rex identity -> Rex
```

The native profile targets the pinned sing-box 1.14.4, including typed DNS servers and a Tailscale
endpoint. The shared NixOS profile reuses `packages/sub2singbox.nix` in node-only mode; it does not
import the legacy generic DNS/routing template. Host parameters now live in `hosts/ymir/config.nix`.
See [shared profile configuration](shared-profile.md) for reuse on another host.

The shared-module/converter refactor is prepared but has not been switched into the running system.
The live-validation results above describe the preceding deployment.

- System `ymir` stays enabled, with its Mullvad exit node explicitly cleared and accepted DNS/subnet
  routes disabled. Existing SSH/Taildrop access keeps this identity.
- `ymir-singbox` has its own persistent state, does not create another system Tailscale interface,
  does not advertise routes, and does not run an SSH server. Routed incoming endpoint connections
  are rejected; this is not a replacement for the system identity's inbound services.
- `ymir-rex` is unchanged. Rex process traffic uses the direct outbound.
- Tailscale endpoint `detour: Proxy` controls its control-plane dialing. Do not assume every peer
  transport connection is proxied. Peer/DERP behavior and ACLs require live testing.

The profile reuses the tested routing helper `scripts/mihomo-tailnet-routing.sh`. Its name is
historical: table 2022 is shared by the two mutually exclusive backend profiles. Priorities 5260 and
5261 preserve system-Tailscale replies and send ordinary Tailnet outbounds to the selected TUN.
Tailscaled's marked transport rules remain before these rules. The sing-box interface is `sb-tun`,
with automatic redirect disabled and incoming `tailscale0` traffic excluded.

`systemd-resolved` forwards to the local DNS inbound at `127.0.0.1:1053`. Tailnet names use the
embedded Tailscale DNS server; bootstrap/control-plane names use direct resolvers. The profile uses
fake-IP for other address queries, and remote CN domain/IP rule sets for direct routing. CN rule-set
downloads still need working direct access or a populated cache. LAN IP access is direct; local DNS
names that depend on router-specific records may need an additional resolver rule.

## Subscription and secrets

Both backends reuse `secrets/services/proxy.yml`. It contains the subscription URL, the downloaded
32-node Trojan bootstrap snapshot, and the controller token, all encrypted with SOPS. Moving the
file does not expand access: its dedicated SOPS rule retains the existing user and ymir recipients.

Only nodes are converted, locally and at runtime. Subscription DNS, routing, groups and listeners
are not imported. The converter preserves TLS SNI, verification, UDP, optional ALPN and TCP Fast
Open. It rejects empty subscriptions, duplicate/reserved tags, other protocols and unsupported
options rather than silently dropping nodes or weakening settings. This is intentionally a converter
for this subscription, not a general replacement for every Clash protocol.

- Public base: `config/sing-box/config.json`; host identity/interface placeholders are rendered by
  Nix.
- Runtime config: `/run/sing-box/config.json`, private to the service account.
- Persistent nodes/cache/endpoint state: `/var/lib/sing-box` (already covered by `/var/lib`
  persistence).
- Controller token: `/run/secrets/singbox_controller_secret` (root-readable).
- Credentials reach the service through systemd `LoadCredential`, not the Nix store or command line.

On startup, the converter uses the last validated online cache, or the encrypted bootstrap snapshot
on first start/snapshot rotation. It validates the generated profile with `sing-box check` before
publishing it. An empty/invalid subscription never becomes a direct fallback. A lock serializes
startup generation and subscription refresh.

Refresh directly, without using the selected proxy:

```sh
sudo systemctl start sing-box-subscription.service
journalctl -u sing-box-subscription.service -n 30
```

The timer starts after boot and refreshes daily. The downloader binds to the physical default-route
interface and uses direct DoH with a pinned resolver address, bypassing both the TUN and the system
fake-IP resolver. The current host has returned HTTP 403 on direct requests even though the same
subscription works on other devices; that is not treated as a universal service restriction. Failed
downloads/conversions leave the existing configuration and node cache untouched. Successful
refreshes restart sing-box if it is running, which can interrupt existing connections.

The WebUI changes selection, not the local SOPS subscription source. Use the service above for node
updates. Keep the encrypted bootstrap snapshot current when rotating credentials; plaintext
downloads and generated configs must never be committed.

## WebUI and authentication

After activation, open **http://127.0.0.1:9090/ui/**. MetaCubeXD is bundled by Nix. Configure the
backend as `http://127.0.0.1:9090`, using the controller token. API access is authenticated; no
controller port is opened in the firewall. The local mixed proxy is `127.0.0.1:7890`.

The Auto exclusion, AI and service selectors below were activated by the full system switch on
2026-11-08. The build also incorporated the existing upstream MCP-fetch and OpenCode build fixes.

In **Proxy**, choose **Auto** for latency-based selection or choose a node manually. Auto excludes
Hong Kong labels (`🇭🇰`, `香港`, `HK`/`HKG`, and Hong Kong spelling variants); all nodes remain
available for manual selection. This is label-based filtering, not an IP geolocation guarantee. A
subscription with no eligible Auto nodes is rejected, preserving the previous valid cache/config.

The **🤖 ChatGPT**, **🤖 Claude**, **🤖 Gemini**, and **🤖 Copilot** selectors default to **Proxy**.
Each can instead use **Auto** or any individual node, including Hong Kong. Their public domain/IP
rules were copied from the existing shared Clash profile in `secrets/services/clash.yaml`, without
copying credentials, subscription URLs, DNS settings, or unrelated rules. They are inline rule sets,
so they do not introduce another rule download dependency.

`config/sing-box/policy.yml` adds 20 service selectors from the public rule portion of that same
Clash profile: Telegram, YouTube, Netflix, Disney+, Bahamut, Bilibili, Google FCM, OneDrive,
Microsoft, Apple, games, NetEase Music, Cloudflare, TikTok, HBO, Prime Video, Hulu, DAZN, Steam
downloads and Steam web. Direct/proxy defaults follow the source profile, except Cloudflare now
defaults to **Proxy** rather than direct. All service selectors offer current subscription nodes,
including Hong Kong; stale node names from the old profile are not copied. Advertising and
application-cleanup blocking groups, generic REJECT rules and the old global fallback are omitted.
The existing Tailnet, LAN, Rex and domestic routing safeguards remain in place.

**☁️ CloudFlare** can follow **Proxy**, **Auto**, any of the four AI selectors, direct, or a node.
For example, selecting **🤖 Claude** makes Cloudflare follow Claude's selected exit. Shared
`challenges.cloudflare.com` and Cloudflare Insights traffic belongs to this group, not Copilot or
ChatGPT; the OpenAI-specific `chat.openai.com.cdn.cloudflare.net` still belongs to ChatGPT.
Cloudflare IPv4/IPv6 ranges are snapshots of <https://www.cloudflare.com/ips-v4> and
<https://www.cloudflare.com/ips-v6>, verified on 2026-11-08. These classify literal destination IPs;
we do not force DNS lookups to guess which CDN hosts an otherwise unknown domain.

Use **Rule** mode. AI-specific domains take precedence over general service/CDN rules. Specific
service domains, including YouTube and FCM, take precedence over Gemini's broad `google.com` and
`googleapis.com` fallback. Steam's download/web rules precede the general games group, and DAZN's
specific CloudFront hosts precede Prime Video's broad CloudFront fallback. These order corrections
keep the narrower selectors usable instead of inheriting shadowed rules from the old profile.
Service IP rules follow domain rules, before the domestic fallback. Other shared AI
authentication/telemetry domains retain ChatGPT-first behavior; selecting an AI exit can therefore
still affect more than its main website. Service and AI DNS queries use fake-IP before the domestic
DNS rule so TUN connections retain their domain for routing.

A shared Cloudflare hostname cannot identify which AI browser session initiated a request. If AI
groups use different exits, manually align Cloudflare with the AI currently in use, or keep all on
the same fixed exit. This is not a guarantee against Cloudflare challenges or HTTP 403 responses.
The rule snapshots are reviewed local configuration, not automatically updated by the node
subscription. Updating the source Clash profile does not automatically rewrite these snapshots.

Selection and fake-IP state persist in the private cache database. The panel's provider-update
controls are not a replacement for `sing-box-subscription.service`. Routing to an AI group does not
guarantee that a provider accepts a particular node's IP or account.

For remote access from a Tailnet-connected device, open **https://ymir.tail2cfd9e.ts.net/ui/** and
use **https://ymir.tail2cfd9e.ts.net** as the backend. Use the same controller token; it is not
replaced by the Tailscale login. No SSH tunnel is needed.

`sing-box-tailnet-webui.service` manages a node-local Tailscale Serve HTTPS mapping on port 443 from
`/` to `http://127.0.0.1:9090`. This uses the existing system **ymir** identity, independently of
the embedded **ymir-singbox** endpoint's login. It does not enable Funnel, expose the mixed proxy
port, or add a LAN/public controller listener. Tailnet ACLs still govern access, and API requests
without the token are rejected. HTTPS certificate names appear in public certificate transparency
logs; this does not make the service publicly reachable.

The service owns only the root HTTPS handler on port 443 and removes it when stopped; it does not
reset other Serve mappings. Reserve that handler for this controller. `tailscale serve status` and
`tailscale funnel status` show the current exposure. `tailscale serve --bg` persists its mapping in
the system Tailscale state across reboots.

Initial enablement used `tailscale serve --bg`. The full NixOS switch has now installed and enabled
`sing-box-tailnet-webui.service`, which manages the same mapping. HTTPS UI access and
unauthenticated API rejection were verified from the Mac.

The local URL remains available, and an SSH tunnel is still an optional fallback:

```sh
ssh -N -L 19090:127.0.0.1:9090 johnson@ymir
```

Then open `http://127.0.0.1:19090/ui/` with that loopback address as the backend. Do not put the
token in a URL or share logs containing Tailscale authentication URLs.

The embedded endpoint starts with sing-box. When its control-plane connection succeeds, follow the
interactive login URL from `journalctl -u sing-box` to authorize **ymir-singbox**. It does not reuse
the system/Rex identity or auth state. System `tailscale status` does not describe the embedded
endpoint.

## Validation and activation

```sh
SUB2SINGBOX="$(nix build --no-link --print-out-paths .#sub2singbox)/bin/sub2singbox" \
  SING_BOX="$(command -v sing-box)" \
  python3 -m unittest discover -s scripts/tests -p 'test_sing_box_subscription.py' -v
bash scripts/tests/test-mihomo-tailnet-routing.sh
nix build --no-link .#nixosConfigurations.ymir.config.system.build.toplevel
```

The Python tests require PyYAML, which is included in the packaged runtime. Set `SING_BOX` to the
pinned sing-box executable to also exercise the real core's AI rule-set matcher. Validate the
generated profile with the pinned core, not the public base alone: its empty Auto group is filled at
runtime. Do not run the subscription generator manually against the live service directories without
its systemd credentials/environment.

Before activation, retain a local console or independent recovery session. After activation verify
public/Chinese/LAN connectivity, DNS, IPv6, manual/Auto selection, subscription refresh, Tailnet
outbounds and inbound SSH/Rex from another device. Tests in a network namespace do not prove node
health, Tailnet login, NAT traversal or ACL permissions.

Rollback by switching to the previous NixOS generation, not merely stopping sing-box: resolved is
configured to depend on its DNS listener. Alternatively select the retained `mihomo` backend and
build/switch that configuration. Each backend has separate endpoint state; neither deletes the
system or Rex Tailscale identity.
