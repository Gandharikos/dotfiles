# Mihomo Quick Start

## Design

- `mode = "service"` uses standalone Mihomo
- `mode = "desktop"` uses Clash Verge
- NixOS service mode starts `services.mihomo` through systemd automatically
- Darwin service mode keeps manual startup by default

## Quick Configuration

### NixOS service mode

```nix
{
  my.networking.proxy = {
    enable = true;
    mode = "service";    # Default
    enableWebui = true;  # Default
  };
}
```

### Darwin service mode

```nix
{
  my.networking.proxy = {
    enable = true;
    mode = "service";    # Default
    autoStart = false;   # Default on Darwin
    enableWebui = true;  # Default
  };
}
```

### Desktop mode

```nix
{
  my.networking.proxy = {
    enable = true;
    mode = "desktop";
  };
}
```

`service` mode requires `mihomo_config` in `secrets/services/mihomo.yaml`. `desktop` mode does not.

## Rebuild

```bash
# NixOS
sudo nixos-rebuild switch --flake .

# Darwin
darwin-rebuild switch --flake .
```

## Use It

### Service mode

- NixOS: the `mihomo` systemd service starts automatically
- Darwin: run `mihomo -d ~/.config/mihomo`, or set `autoStart = true`
- WebUI: open `http://localhost:9090/ui` when `enableWebui = true`

### Desktop mode

- NixOS: run `clash-verge`
- Darwin: open Clash Verge from Launchpad or run `open -a "Clash Verge"`

## Paths

### Service mode on NixOS

- Config: `/var/lib/mihomo/config.yaml`
- Logs: `sudo journalctl -u mihomo`

### Service mode on Darwin

- Config: `~/.config/mihomo/config.yaml`
- Logs: `/var/log/mihomo.log`

## Manual Management

### NixOS service mode

```bash
sudo systemctl stop mihomo
sudo systemctl status mihomo
sudo journalctl -u mihomo -f
```

### Darwin service mode

```bash
mihomo -d ~/.config/mihomo
pkill mihomo
```

## More

See `docs/MIHOMO_USAGE.md` for the full guide.
