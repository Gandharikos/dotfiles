# Shared subscription/Tailnet profile

These are reusable, opinionated **NixOS** presets. They are not automatically enabled on other
hosts, and do not replace the existing Darwin or explicitly configured legacy proxy integrations.
The old bundled Clash secret has been removed. Enabling a backend without this profile now requires
an explicit runtime `mihomo.configFile` / `singBox.configFile`, or an explicitly managed SOPS secret
(`proxy_config` / `proxy_source_config` respectively). There is no implicit shared secret fallback.
The NixOS profile continues to use `secrets/services/proxy.yml` unchanged.

`dot.networking.proxy.backend` accepts only `mihomo` or `sing-box`. The optional dae wrapper and its
`dot.networking.proxy.dae` options have been removed; remove any old assignments, including
explicitly disabled ones. No current host enabled the wrapper, and this removal does not change the
shared profile's DNS, routing or backend selection. The Darwin backends provide native CLIs and
private configuration directories, without automatically starting a TUN. Clash-format subscriptions
and the Clash-compatible controller API do not require a desktop client. Darwin retains the
`clash-verge-rev` Homebrew cask as an independent GUI; it is not a `dot.networking.proxy.backend`
choice.

```text
host parameters + SOPS credentials
                |
       shared NixOS profile
                |
Clash nodes -> sub2singbox -> fidelity checks -> policy/groups -> sing-box check -> private runtime file
```

## Enable on another NixOS host

```nix
{ self, ... }:
{
  dot.networking.tailscale = {
    role = "client";
    exitNode = "";
    acceptRoutes = false;
    acceptDns = false;
  };
  dot.networking.proxy = {
    enable = true;
    backend = "sing-box";
    autoStart = true;
    profile = {
      enable = true;
      secretsFile = "${self}/secrets/services/proxy.yml";
      ports = {
        mixed = 7890;
        dns = 1053;
        controller = 9090;
      };
      tailnet = {
        domain = "your-tailnet.ts.net";
        webUI.enable = true;
      };
    };
  };
}
```

The encrypted subscription file must contain `subscription_nodes`, `subscription_url`, and
`controller_secret`. The dedicated rule for `secrets/services/proxy.yml` retains the existing user
and ymir recipients; its shared path does not grant other hosts access. Authorize additional SOPS
recipients separately. Never put decrypted values into Nix options, templates, command arguments or
Git.

- The embedded hostname defaults to `<networking.hostName>-singbox` (or `-mihomo` for that backend).
  Override `profile.tailnet.hostname` if needed. Each host keeps its own private embedded Tailscale
  state and needs separate authorization; do not copy another host's state directory.
- `profile.ports.mixed`, `profile.ports.dns`, and `profile.ports.controller` default to 7890, 1053,
  and 9090, on loopback. They apply only to this shared profile, not externally supplied core
  configurations.
- `profile.tailnet.webUI.enable` defaults to false and supports both sing-box and Mihomo. It manages
  only the root HTTPS handler on `profile.tailnet.webUI.httpsPort` (443 by default), forwarding to
  `127.0.0.1:${profile.ports.controller}` without enabling Funnel. The service is named
  `<backend>-tailnet-webui`; controller authentication remains required. Serve follows
  `proxy.autoStart`; disabling it leaves the unit manual, as with the sing-box refresh timer.
- Tailnet options, validation and Serve live in
  `modules/nixos/networking/proxy/tailnet-profile.nix`.
- The proxy uses route table 2022 with policy priorities starting at 9000. System Tailscale owns
  table 52 and its earlier transport/peer rules. Neither profile installs the former 5260/5261
  overrides. Both TUN templates exclude `100.64.0.0/10` and `fd7a:115c:a1e0::/48`.

## Files and responsibilities

| File                                                  | Role                                                                        |
| ----------------------------------------------------- | --------------------------------------------------------------------------- |
| `config/sing-box/config.json`                         | Native base, AI rules, and host/interface placeholders                      |
| `config/sing-box/policy.yml`                          | Public service selectors and rule snapshots                                 |
| `config/mihomo/config.yaml`                           | Mihomo base: listeners, DNS, TUN, subscription and Tailnet                  |
| `config/mihomo/policy.yaml`                           | Mihomo proxy groups, rule providers and ordered routing rules               |
| `modules/nixos/networking/proxy/profile.nix`          | Opt-in host parameters and system DNS                                       |
| `modules/nixos/networking/proxy/tailnet-profile.nix`  | Tailnet options, identity validation and node-local Serve                   |
| `modules/nixos/networking/proxy/sing-box-profile.nix` | Conversion, refresh and private credentials                                 |
| `modules/nixos/networking/proxy/mihomo-profile.nix`   | Alternative provider cache and SOPS rendering                               |
| `scripts/sing-box-subscription.py`                    | Input/output validation, policy assembly, last-good cache and atomic writes |
| `packages/sub2singbox.nix`                            | Pinned upstream node converter and Trojan URI password fix                  |

Use `profile.singBox.template`, `profile.singBox.policy`, `profile.mihomo.template`, and
`profile.mihomo.policy` to select other public files. Custom sing-box templates must retain the
bootstrap DNS resolver, selector names and rule insertion anchors used by the generator; these are
presets, not arbitrary config mergers. The node-only conversion never imports subscription DNS,
listeners or routing rules. The sing-box policy loader accepts YAML and legacy JSON, and requires
all five policy section lists; empty or malformed policy files fail without replacing the last valid
runtime configuration.

The Mihomo base and policy are YAML mapping fragments concatenated into one document, not an
override/deep-merge mechanism. Keep `proxy-groups`, `rule-providers`, and `rules` in the policy,
with other top-level keys in the base. Do not duplicate keys or add YAML document separators. Rule
list order is preserved. Its DNS policy still refers to the `cn-domain` provider, and its Tailnet
endpoint still uses the `Proxy` group; retain those references when replacing the policy.

Mihomo rendering has two separate stages:

1. Nix substitutes public host/port parameters and replaces secret markers in the external YAML with
   `config.sops.placeholder.<secret>` values. These are opaque placeholders, not secrets.
2. sops-nix fills those placeholders in `sops.templates."proxy-mihomo.yaml"` during activation/boot.
   The resulting file is mode `0400` and reaches the daemon via systemd `LoadCredential`.

`replaceStrings` bridges the external YAML to Nix/SOPS; it does not decrypt SOPS data. Unlike a Nix
string, a file loaded with `builtins.readFile` does not evaluate Nix interpolation. No plaintext
subscription URL or controller token is needed during evaluation or builds.

The conversion adapter deliberately retains the validated **basic Trojan** input contract. Reusing a
multi-protocol converter does not automatically make every protocol/option safe: unsupported input,
dropped/renamed nodes, changed credentials or changed TLS settings reject the entire update. Add
protocol-specific fidelity tests before expanding that contract. The adapter restores UDP/TFO flags
omitted by the pinned converter. Its output and diagnostics stay private; only local temporary file
paths reach its argument list. Conversion does not download the subscription or templates.

Auto still excludes Hong Kong **labels**, while manual selectors retain those nodes. Policy
snapshots are shared, reviewed data; node refresh does not update service rules. The alternative
Mihomo preset retains its existing policy, not the sing-box-only policy YAML. Its historical
`providers/wgetcloud.yaml` cache basename is retained so changing the provider's display name to
`Subscription` does not discard a newer online snapshot.

## System, proxy and Rex identities

```text
Native Tailnet connections / tailscale ssh / Taildrop -> system tailscaled
Explicit SOCKS/HTTP requests -> core routing rules -> embedded Tailnet endpoint
Rex sessions -> Rex's independent Tailscale identity and transport
```

Keep the system client's native route and transport bypasses. Do not force its private destinations
through the proxy TUN: Linux Tailscale's anti-spoof filter rejects CGNAT-sourced replies on another
interface. No firewall exception, blanket trusted TUN, or disabled Tailscale filter is needed for
this architecture. The experimental SSH-only reply helper was withdrawn, not deployed permanently.

The existing application-level Tailnet rules and embedded state remain available through the mixed
listener. For example, `ssh -o 'ProxyCommand=nc -x 127.0.0.1:7890 -X 5 %h %p' user@TAILNET_IP` uses
the proxy endpoint; plain `tailscale ssh` and `tailscale file` use the system client. This does not
make the system client's outer transport use a subscription proxy. No proxy environment is added to
system tailscaled. Ordinary system DNS still uses the proxy resolver; preserving native Tailnet
routes is not a promise that all hostname resolution survives a proxy outage.

Rex is a separate client, not an alias for the proxy's embedded identity. A remote Rex client may
need proxy assistance for its outer transport even when system Tailscale works directly. This change
does not alter Rex's current process rule or state; that transport path needs separate validation
before any routing changes.

On activation, the old `<backend>-tailnet-routing.service` must stop and run its existing `ExecStop`
to remove the owned 5260/5261 rules. Check both address families afterward. A build alone does not
clean live routes. Do not flush policy rules or Tailscale's firewall chains.

## Validation

With PyYAML available:

```sh
SUB2SINGBOX="$(nix build --no-link --print-out-paths .#sub2singbox)/bin/sub2singbox" \
  SING_BOX="$(command -v sing-box)" \
  python3 -m unittest discover -s tests -p 'test_sing_box_subscription.py' -v
python3 -m unittest discover -s tests -p 'test_mihomo_profile.py' -v
bash tests/test-tailnet-routing.sh
nix --extra-experimental-features pipe-operators eval --impure --json \
  --file tests/proxy-backends.nix
for backend in sing-box mihomo; do
  nix --extra-experimental-features pipe-operators eval --impure \
    --file tests/proxy-profile.nix --argstr backend "$backend" checks
  nix --extra-experimental-features pipe-operators eval --impure \
    --file tests/proxy-profile.nix --argstr backend "$backend" \
    --argstr hostname custom-endpoint --arg webUI false checks
  nix --extra-experimental-features pipe-operators build --impure --no-link \
    --file tests/proxy-profile.nix --argstr backend "$backend" unit webUIUnit
done
nix build --no-link .#nixosConfigurations.<host>.config.system.build.toplevel
```

Unit tests use a converter fixture. Setting `SUB2SINGBOX` additionally exercises the real packaged
converter, including reserved password characters and transport flags. Setting `SING_BOX` exercises
real rule matching. The Nix fixture overrides the hostname, Tailnet domain and ports, checks both
backends and verifies that disabling auto-start leaves the auxiliary units manual. It only
builds/evaluates configuration; it never activates a host or decrypts credentials.

Before deployment, validate the actual subscription privately and compare the rendered config;
neither test fixtures nor `nix build` alone prove runtime connectivity.
