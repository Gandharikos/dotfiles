# Clash/Mihomo Proxy Quick Start

## Design

Automatic proxy implementation based on environment:

- Mode is automatically determined by `my.gui.enable`:
  - **`gui.enable = true`**: Clash Verge GUI (desktop environments)
  - **`gui.enable = false`**: mihomo core + WebUI (servers/headless)
- **NixOS**:
  - GUI: `programs.clash-verge`
  - Headless: `services.mihomo` + metacubexd WebUI
- **Darwin**:
  - GUI: Clash Verge via Homebrew
  - Headless: mihomo core via launchd

## Quick Configuration

### Minimal Setup

```nix
{
  my.networking.proxy.enable = true;
  # Mode auto-determined by my.gui.enable
}
```

### With Auto-Start

```nix
{
  my.networking.proxy = {
    enable = true;
    autoStart = true;  # Start on boot
  };
}
```

### Example: Server (No GUI)

```nix
{
  my.gui.enable = false;  # Service mode
  my.networking.proxy = {
    enable = true;
    autoStart = true;
  };
}
```

### Example: Desktop (With GUI)

```nix
{
  my.gui.enable = true;  # GUI mode
  my.networking.proxy.enable = true;
}
```

## Setup

1. Ensure `secrets/services/mihomo.yaml` contains encrypted `mihomo_config`
2. Rebuild system:

```bash
# NixOS
sudo nixos-rebuild switch --flake .

# Darwin
darwin-rebuild switch --flake .
```

## Usage

### GUI Mode (`my.gui.enable = true`)

**NixOS:**

```bash
clash-verge
```

**Darwin:**

```bash
open -a "Clash Verge"
```

### Service Mode (`my.gui.enable = false`)

**NixOS:**

- Service starts automatically via systemd
- Manage: `sudo systemctl status clash-verge`

**Darwin:**

- Configure service mode in Clash Verge settings (one-time)
- Clash Verge will run as background service

## Configuration Location

- **NixOS**: `/var/lib/mihomo/config.yaml`
- **Darwin**: `~/.config/mihomo/config.yaml`

## More Information

See `docs/MIHOMO_USAGE.md` for detailed documentation.
