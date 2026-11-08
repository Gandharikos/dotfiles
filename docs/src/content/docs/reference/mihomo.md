---
title: Mihomo
description: Native proxy backends and the independent Darwin GUI.
---

`dot.networking.proxy.backend` selects `mihomo` (the default) or `sing-box`:

- NixOS uses the selected system service on both desktop and headless hosts. `dot.gui.enable` does
  not select a different backend. Clash Verge installation, desktop autostart, groups, and
  persistence are no longer managed by the NixOS proxy modules.
- Darwin provides native CLIs and private configuration directories, without automatically starting
  a TUN. Mihomo uses `~/.config/mihomo/config.yaml`.
- Darwin retains the independent `clash-verge-rev` Homebrew cask. It is not a proxy backend, and its
  configuration is not managed by the native Mihomo module.

## Minimal Configuration

```nix
{
  dot.networking.proxy = {
    enable = true;
    backend = "mihomo";
    mihomo.configFile = "/run/secrets/my-mihomo.yaml";
  };
}
```

Supply that private runtime file separately; the old bundled encrypted Clash configuration is no
longer loaded. On Darwin, use the user's `~/.config/mihomo/config.yaml` as an absolute path, or pass
another explicit path to the CLI. Do not place plaintext credentials in the Nix store. For managed
NixOS subscription configuration, use the shared profile documented in
`docs/proxy/shared-profile.md`, which supplies the runtime config automatically.

## Auto-Start On NixOS

```nix
{
  dot.networking.proxy = {
    enable = true;
    backend = "mihomo";
    mihomo.configFile = "/run/secrets/my-mihomo.yaml";
    autoStart = true;
  };
}
```

## Service Commands

```bash
sudo systemctl status mihomo
sudo journalctl -u mihomo -f
```

With a controller configured on loopback port 9090, the WebUI is available at
`http://127.0.0.1:9090/ui/` while Mihomo is running. Use the configured controller token for API
access. Do not expose the controller on `0.0.0.0` merely to access the dashboard remotely.
