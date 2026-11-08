# Optional independent dae service (NixOS only)

`modules/nixos/networking/proxy/dae.nix` reuses upstream `services.dae`. It is **off by default**.
Dae is not a `dot.networking.proxy.backend` value: that selector remains `mihomo` or `sing-box`.
Instead, `dot.networking.proxy.dae.enable` independently enables dae, alongside either core or
without a main core. Ymir keeps sing-box enabled and dae disabled. Darwin does not expose this
module; its `clash-verge-rev` Homebrew cask remains available.

Add these options to a host without changing its existing backend or shared profile:

```nix
{ config, self, ... }:
{
  sops.secrets.dae_config = {
    sopsFile = "${self}/secrets/hosts/example/dae.yaml";
    key = "config";
    mode = "0400";
    restartUnits = [ "dae.service" ];
  };
  dot.networking.proxy.dae = {
    enable = true;
    autoStart = false;
    configFile = config.sops.secrets.dae_config.path;
  };
}
```

Both `dae.enable` and `dae.autoStart` default to false. They do not inherit the main proxy's
`enable` or `autoStart`. Setting `proxy.enable = false` therefore does not disable an explicitly
enabled dae service. With `dae.autoStart = false`, start `dae.service` manually after validation.

Create the encrypted secret separately; its `config` value must contain a valid native `.dae`
configuration. Do not put subscription URLs or node credentials in `services.dae.config`, a Nix
string, or a plaintext repository file. Upstream passes `configFile` through systemd
`LoadCredential` and validates it before starting the daemon.

## Cooperation with a core

Dae and the chosen core are allowed to run together. Mihomo and sing-box remain mutually exclusive
as main system backends. Enabling dae does not disable the shared profile, change system DNS, start
the main core, or automatically connect the two services.

Define the traffic path explicitly in the native configurations: interception interfaces, local
proxy handoff, DNS ownership, and bypasses for the core's own outbound connections. Avoid
overlapping TUN/eBPF capture, proxy loops and DNS loops. Preserve system Tailscale and Rex transport
bypasses. If dae owns interception in your design, configure the core's listeners/TUN accordingly;
the existing shared TUN preset is not automatically rewritten into a proxy-only preset.

- Existing subscriptions, service groups, embedded Tailscale state and WebUI stay with the main
  core. This module does not convert subscriptions or copy credentials between services.
- No firewall ports are opened by this wrapper. If a gateway configuration needs them, explicitly
  set `services.dae.openFirewall` and match its port to the native `tproxy_port`.
- The kernel must support dae's eBPF requirements. Protect remote access with a rollback plan before
  deploying any new interception policy.

Evaluation-only regression checks cover default-off behavior, independent enable/auto-start,
coexistence with each shared profile, unchanged system DNS and runtime credential handling:

```sh
nix --extra-experimental-features pipe-operators eval --impure --json \
  --file tests/dae.nix
```

These checks do not start services or install kernel hooks. Runtime dae/core cooperation has not
been tested as part of adding this disabled option.
