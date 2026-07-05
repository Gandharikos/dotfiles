---
title: Mihomo
description: Proxy module behavior across desktop and headless hosts.
---

The proxy module chooses behavior from the host environment:

- GUI hosts use Clash Verge as the user-facing frontend.
- Headless NixOS hosts use the `mihomo` system service and WebUI.
- Darwin hosts use Clash Verge through Homebrew.

## Minimal Configuration

```nix
{
  dot.networking.proxy.enable = true;
}
```

## Auto-Start On Headless NixOS

```nix
{
  dot.gui.enable = false;
  dot.networking.proxy = {
    enable = true;
    autoStart = true;
  };
}
```

## Service Commands

```bash
sudo systemctl status mihomo
sudo journalctl -u mihomo -f
```

The WebUI is available at `http://localhost:9090/ui` when the service is running.

For detailed notes, see `docs/MIHOMO_QUICKSTART.md` and `docs/MIHOMO_USAGE.md`.
