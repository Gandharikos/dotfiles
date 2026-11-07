# ymir: sing-box + embedded Tailscale

The active backend is now `sing-box`. The Mihomo profile remains available by changing
`dot.networking.proxy.backend` back to `"mihomo"`. Never start both TUN/controller services
together. No dae or Clash desktop client is used.

## Live validation (2026-11-08)

- Full ymir build, seven subscription tests, routing tests, and core validation of all 32 nodes
  passed.
- Domestic/public HTTPS, IPv6, DNS, WebUI and authenticated controller access passed.
  Unauthenticated API requests return 401; listeners remain loopback-only. Manual selection passed,
  then `Auto` was restored.
- System Tailscale has no exit node. Existing inbound SSH and the Rex service remain available.
- `ymir-singbox` still needs its first interactive Tailscale login. Embedded Tailnet outbounds are
  not yet verified; retrieve the authentication link privately from the sing-box journal.
- Direct subscription refresh still returns HTTP 403 on this host. The valid 32-node snapshot
  remains active; the refresh failure does not replace it or stop sing-box.

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
endpoint. The legacy generic subscription generator is not used for this host.

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

Both backends reuse `secrets/hosts/ymir/mihomo.yaml`; its filename does not imply a running Mihomo
service. It contains the subscription URL, the downloaded 32-node Trojan bootstrap snapshot, and the
controller token, all encrypted with SOPS.

Only nodes are converted, locally and at runtime. Subscription DNS, routing, groups and listeners
are not imported. The converter preserves TLS SNI, verification, UDP, optional ALPN and TCP Fast
Open. It rejects empty subscriptions, duplicate/reserved tags, other protocols and unsupported
options rather than silently dropping nodes or weakening settings. This is intentionally a converter
for this subscription, not a general replacement for every Clash protocol.

- Public base: `config/sing-box/ymir.json`.
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

In **Proxy**, choose **Auto** for latency-based selection or choose a node manually. Selection and
fake-IP state persist in the private cache database. The panel's provider-update controls are not a
replacement for `sing-box-subscription.service`.

For remote access, forward the controller over the existing system Tailscale SSH connection:

```sh
ssh -N -L 19090:127.0.0.1:9090 johnson@ymir
```

Open `http://127.0.0.1:19090/ui/` and use that loopback address as the backend. Do not put the token
in a URL or share logs containing Tailscale authentication URLs.

The embedded endpoint starts with sing-box. When its control-plane connection succeeds, follow the
interactive login URL from `journalctl -u sing-box` to authorize **ymir-singbox**. It does not reuse
the system/Rex identity or auth state. System `tailscale status` does not describe the embedded
endpoint.

## Validation and activation

```sh
python3 -m unittest discover -s scripts/tests -p 'test_sing_box_subscription.py' -v
bash scripts/tests/test-mihomo-tailnet-routing.sh
nix build --no-link .#nixosConfigurations.ymir.config.system.build.toplevel
```

The Python tests require PyYAML, which is included in the packaged runtime. Validate the generated
profile with the pinned core, not the public base alone: its empty Auto group is filled at runtime.
Do not run the subscription generator manually against the live service directories without its
systemd credentials/environment.

Before activation, retain a local console or independent recovery session. After activation verify
public/Chinese/LAN connectivity, DNS, IPv6, manual/Auto selection, subscription refresh, Tailnet
outbounds and inbound SSH/Rex from another device. Tests in a network namespace do not prove node
health, Tailnet login, NAT traversal or ACL permissions.

Rollback by switching to the previous NixOS generation, not merely stopping sing-box: resolved is
configured to depend on its DNS listener. Alternatively select the retained `mihomo` backend and
build/switch that configuration. Each backend has separate endpoint state; neither deletes the
system or Rex Tailscale identity.
