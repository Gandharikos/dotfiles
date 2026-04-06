# Mihomo Usage Guide

## Architecture

- `mode = "service"` uses standalone Mihomo
- `mode = "desktop"` uses Clash Verge
- NixOS service mode enables `services.mihomo`
- Darwin service mode installs `mihomo` and can optionally create a launchd daemon

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
    autoStart = false;
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

Service mode requires `mihomo_config` in `secrets/services/mihomo.yaml`. Desktop mode does not.

## Option Reference

### `enable`

- Type: `boolean`
- Default: `true`
- Meaning: enable proxy integration

### `backend`

- Type: `"mihomo"`
- Default: `"mihomo"`
- Meaning: select the proxy backend

### `mode`

- Type: `"service" | "desktop"`
- Default: `"service"`
- Meaning: choose between standalone Mihomo service mode and Clash Verge desktop mode

### `enableWebui`

- Type: `boolean`
- Default: `true`
- Meaning: enable the WebUI package in service mode

### `autoStart`

- Type: `boolean`
- Default: `false`
- Meaning: auto-start the Mihomo daemon on Darwin in service mode

## Mode Behavior

### Service mode on NixOS

- Enables `services.mihomo`
- Starts through systemd automatically
- Uses the encrypted `mihomo_config` secret
- Can expose WebUI at `http://localhost:9090/ui`

### Service mode on Darwin

- Installs `mihomo`
- Uses the encrypted `mihomo_config` secret
- Supports WebUI at `http://localhost:9090/ui`
- Runs manually by default, or via launchd when `autoStart = true`

### Desktop mode

- NixOS enables `programs.clash-verge`
- Darwin installs the `clash-verge-rev` Homebrew cask
- Does not enable the standalone Mihomo service
- Does not use the encrypted `mihomo_config` deployment path

## Starting and Stopping

### NixOS service mode

```bash
sudo systemctl stop mihomo
sudo systemctl restart mihomo
sudo systemctl status mihomo
sudo journalctl -u mihomo -f
```

### Darwin service mode

```bash
mihomo -d ~/.config/mihomo
pkill mihomo
```

### Desktop mode

```bash
# NixOS
clash-verge

# Darwin
open -a "Clash Verge"
```

## Config and Logs

### Service mode on NixOS

- Config file: `/var/lib/mihomo/config.yaml`
- Logs: `journalctl -u mihomo`

### Service mode on Darwin

- Config file: `~/.config/mihomo/config.yaml`
- Logs: `/var/log/mihomo.log` and `/var/log/mihomo-error.log`

## Examples

### NixOS service mode with WebUI

```nix
{
  my.networking.proxy = {
    enable = true;
    mode = "service";
    enableWebui = true;
  };
}
```

### Darwin service mode with manual start

```nix
{
  my.networking.proxy = {
    enable = true;
    mode = "service";
    autoStart = false;
    enableWebui = true;
  };
}
```

### Darwin service mode with launchd auto-start

```nix
{
  my.networking.proxy = {
    enable = true;
    mode = "service";
    autoStart = true;
    enableWebui = true;
  };
}
```

### Desktop mode on either platform

```nix
{
  my.networking.proxy = {
    enable = true;
    mode = "desktop";
  };
}
```

## Migration

If you were using `enableGui` before, switch to `mode`:

```nix
my.networking.proxy = {
  enable = true;
  mode = "service";  # or "desktop"
};
```

`enableGui = true` maps most closely to `mode = "desktop"` if your intent was to use Clash Verge.

## Troubleshooting

### Service mode failed to start

```bash
# NixOS
sudo journalctl -u mihomo -n 50

# Darwin
tail -50 /var/log/mihomo-error.log
```

### WebUI is unavailable

- Confirm `mode = "service"`
- Confirm `enableWebui = true`
- Open `http://localhost:9090/ui`

### Port conflict

```bash
sudo lsof -i :9090
```

## References

- Mihomo Wiki: https://wiki.metacubex.one/
- NixOS Wiki: https://nixos.wiki/wiki/Mihomo
- Clash Verge: https://github.com/clash-verge-rev/clash-verge-rev
