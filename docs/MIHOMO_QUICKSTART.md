# Clash/Mihomo Proxy Quick Start

## Design

Automatic proxy implementation based on environment:

- Mode is automatically determined by `dot.gui.enable`:
  - **`gui.enable = true`**: Clash Verge GUI (desktop environments)
  - **`gui.enable = false`**: mihomo core + WebUI (servers/headless)
- **NixOS**:
  - GUI: `programs.clash-verge`
  - Headless: `services.mihomo` + metacubexd WebUI
- **Darwin**:
  - Always uses Clash Verge via Homebrew
  - Does not switch to a headless mihomo branch

## Quick Configuration

### Minimal Setup

```nix
{
  dot.networking.proxy.enable = true;
  # Mode auto-determined by dot.gui.enable
}
```

### With Auto-Start

```nix
{
  dot.networking.proxy = {
    enable = true;
    autoStart = true;  # NixOS only
  };
}
```

### Example: Server (No GUI)

```nix
{
  dot.gui.enable = false;  # Service mode
  dot.networking.proxy = {
    enable = true;
    autoStart = true;
  };
}
```

### Example: Desktop (With GUI)

```nix
{
  dot.gui.enable = true;  # GUI mode
  dot.networking.proxy.enable = true;
}
```

## Setup

1. Ensure `secrets/services/clash.yaml` contains encrypted `clash_config`
2. Rebuild system:

```bash
# NixOS
sudo nixos-rebuild switch --flake .

# Darwin
darwin-rebuild switch --flake .
```

## Usage

### GUI Mode (`dot.gui.enable = true`)

**NixOS:**

```bash
clash-verge
```

**Darwin:**

```bash
open -a "Clash Verge"
```

### Service Mode (`dot.gui.enable = false`, NixOS only)

**NixOS:**

- Service starts automatically via systemd
- Manage: `sudo systemctl status clash-verge`

## Configuration Location

- **NixOS GUI**: `~/.config/clash-verge/config.yaml`
- **NixOS headless**: `/var/lib/mihomo/config.yaml`
- **Darwin**: `~/.config/clash-verge/config.yaml`

## More Information

See `docs/MIHOMO_USAGE.md` for detailed documentation.
