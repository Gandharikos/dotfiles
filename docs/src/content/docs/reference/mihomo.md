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
  };
}
```

## Auto-Start On NixOS

```nix
{
  dot.networking.proxy = {
    enable = true;
    backend = "mihomo";
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
