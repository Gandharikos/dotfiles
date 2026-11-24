# dae shared profile

This is an opt-in NixOS profile using the same `proxy.profile.enable`, `secretsFile`, `ports.dns`
and `proxy.autoStart` entry points as sing-box and Mihomo. Neither existing backend's templates or
policies are changed. No host currently enables dae, and these changes are not deployed.

```nix
{ self, ... }:
{
  dot.networking.proxy = {
    enable = true;
    backend = "dae";
    autoStart = false;
    profile = {
      enable = true;
      secretsFile = "${self}/secrets/services/proxy.yml";
      tailnet.domain = "your-tailnet.ts.net";
      dae.wanInterfaces = [ "auto" ];
      dae.lanInterfaces = [ ];
      # Optional override of a saved select-group choice:
      # dae.selections."🚀 节点选择" = "🇯🇵 日本 03";
    };
  };
}
```

The encrypted file needs `subscription_nodes` (a Clash `proxies` document). The existing shared file
is not automatically authorized for Heimdall: grant access separately before any deployment. Only
the currently used basic Trojan node fields are supported. Password encoding, SNI and explicit
`skip-cert-verify` are preserved, not relaxed or silently replaced. Unsupported protocols/options,
TCP-only nodes, missing group members and invalid choices reject generation.

## Public policy and private nodes

- `config/dae/config.dae`: native base with host DNS/interface placeholders.
- `config/dae/policy.dae`: complete ordered Clash routing snapshot, combined only across adjacent
  identical predicates and actions. It includes 15,263 non-empty original rules (including all 45
  process rules), plus Surge's additional `tailscale.com` website rule.
- `config/dae/groups.json`: all 29 select groups, their memberships, saved selections and target
  aliases. The saved primary selection is Japan 03; other groups retain their declared first choice
  unless overridden through `profile.dae.selections`.
- `scripts/dae-profile.py`: renders private nodes, resolves nested selections, validates with the
  selected dae binary and atomically publishes mode-0600 `/run/dae/config.dae`.
- `dae-config.service`: loads the encrypted node seed through systemd credentials before
  `dae.service` loads its generated configuration. Every dae start reruns the prerequisite; SOPS
  seed changes and public policy/selection changes restart dae.

The snapshot was extracted from eir's Clash Verge configuration and compared with Surge's
`WgetCloud-Tailscale-Editable.conf` on 2026-11-24. After normalizing whitespace, quoted targets and
`FINAL`/`MATCH`, Surge has only two additional rules: `tailscale.com` through the selected proxy,
and its MagicDNS suffix through the embedded Tailnet endpoint. The former is included in the public
policy; the latter is parameterized by `profile.tailnet.domain` and uses system Tailscale instead.
No passwords, server endpoints, subscription URLs or controller secrets are exported into these
public files. Original private profile files are not copied into the repository.

Node updates currently follow the SOPS seed, not periodic downloads of `subscription_url`. This
profile deliberately does not add another subscription refresh/control-plane service. Updating the
seed must retain the referenced node names or update the public group snapshot accordingly.

## Backend-specific boundaries

- dae is an eBPF transparent proxy, not an HTTP/SOCKS server. `ports.mixed` and `ports.controller`
  do not create listeners. `tailnet.webUI.enable` is rejected; there is no Clash API, embedded
  Tailnet identity, interactive select-group UI or extra panel service.
- Select groups are resolved to fixed native node groups at generation time. A failed selected proxy
  does not silently become DIRECT. Changing a choice requires regeneration/restart.
- Process rules describe processes on this Linux host. A router cannot identify the original
  application behind forwarded client traffic; domain/IP rules still apply in order.
- Native system Tailscale and Rex process/peer bypasses precede the imported policy. MagicDNS
  queries go to `100.100.100.100`; other DNS queries use certificate-verified Cloudflare DoH.
- WAN defaults to `auto` for host-local interception. LAN interception defaults off. Forwarding,
  firewall exposure, interface sysctls and DHCP remain host-owned; dae's automatic kernel-parameter
  modification is disabled. Enabling LAN interception needs a separate network deployment review.
- `autoStart = false` leaves dae manual, but enabling the shared profile still points the system
  resolver at its DNS port, just like the other profiles. Do not activate a stopped proxy as the
  only resolver on a remotely managed host.

## Validation

```sh
python3 -m unittest discover -s tests -p 'test_dae_profile.py' -v
nix --extra-experimental-features pipe-operators eval --impure --json \
  --file tests/proxy-dae-profile.nix checks
```

Tests use synthetic credentials and check ordering, saved choices, unsupported-input rejection,
TLS/password preservation, private diagnostics, atomic publication and Nix service wiring.
`just regression` passed on 2026-11-24: 78 Python tests (3 expected integration skips) and the
complete default Nix assertion suite. Both generated systemd unit builds, the existing
sing-box/Mihomo profile assertions and networking regressions also passed. The full policy with
synthetic nodes passed the pinned dae 2.1.1 `validate` command on Linux; the actual local Clash node
shape was checked only in memory, without publishing credentials or running interception.
Build/evaluation and `dae validate` do not demonstrate live DNS, eBPF interception or LAN
forwarding; those require a separately approved runtime test. No old Heimdall gateway implementation
is restored.
