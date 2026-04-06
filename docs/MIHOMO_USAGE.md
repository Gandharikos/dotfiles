# Mihomo Usage Guide

## Architecture

- NixOS switches automatically based on `my.gui.enable`
- NixOS GUI hosts use `programs.clash-verge`
- NixOS headless hosts use `services.mihomo` with WebUI
- Darwin always uses Clash Verge via Homebrew

## Quick Configuration

### NixOS GUI host

```nix
{
  my.gui.enable = true;
  my.networking.proxy = {
    enable = true;
  };
}
```

### NixOS headless host

```nix
{
  my.gui.enable = false;
  my.networking.proxy = {
    enable = true;
    autoStart = true;
  };
}
```

### Darwin

```nix
{
  my.networking.proxy = {
    enable = true;
  };
}
```

The module expects encrypted `clash_config` in `secrets/services/clash.yaml`.

## Option Reference

### `enable`

- Type: `boolean`
- Default: `true`
- Meaning: enable proxy integration

### `autoStart`

- Type: `boolean`
- Default: `false`
- Meaning: start the proxy automatically on NixOS

## Behavior

### NixOS with `my.gui.enable = true`

- Enables `programs.clash-verge`
- Deploys `clash_config` to `~/.config/clash-verge/config.yaml`
- Uses Clash Verge for runtime management

### NixOS with `my.gui.enable = false`

- Enables `services.mihomo`
- Deploys `clash_config` to `/var/lib/mihomo/config.yaml`
- Exposes WebUI at `http://localhost:9090/ui`
- Starts through systemd when `autoStart = true`

### Darwin

- Installs the `clash-verge-rev` Homebrew cask
- Deploys `clash_config` to `~/.config/clash-verge/config.yaml`
- Does not branch on `my.gui.enable`

## Starting and Stopping

### NixOS headless

```bash
sudo systemctl stop mihomo
sudo systemctl restart mihomo
sudo systemctl status mihomo
sudo journalctl -u mihomo -f
```

### GUI hosts

```bash
# NixOS
clash-verge

# Darwin
open -a "Clash Verge"
```

## Config and Logs

### NixOS GUI

- Config file: `~/.config/clash-verge/config.yaml`

### NixOS headless

- Config file: `/var/lib/mihomo/config.yaml`
- Logs: `journalctl -u mihomo`

### Darwin

- Config file: `~/.config/clash-verge/config.yaml`

## Examples

### NixOS GUI

```nix
{
  my.gui.enable = true;
  my.networking.proxy = {
    enable = true;
  };
}
```

### NixOS headless with auto-start

```nix
{
  my.gui.enable = false;
  my.networking.proxy = {
    enable = true;
    autoStart = true;
  };
}
```

### Darwin

```nix
{
  my.networking.proxy = {
    enable = true;
  };
}
```

## Migration

If you were using the older Mihomo-specific docs, the current model is:

```nix
my.networking.proxy = {
  enable = true;
};
```

- On NixOS, GUI vs headless is determined by `my.gui.enable`
- On Darwin, Clash Verge is always used

## Troubleshooting

### NixOS headless service failed to start

```bash
# NixOS
sudo journalctl -u mihomo -n 50
```

### WebUI is unavailable

- Confirm `my.gui.enable = false` on NixOS
- Open `http://localhost:9090/ui`

### Port conflict

```bash
sudo lsof -i :9090
```

## References

- Mihomo Wiki: https://wiki.metacubex.one/
- NixOS Wiki: https://nixos.wiki/wiki/Mihomo
- Clash Verge: https://github.com/clash-verge-rev/clash-verge-rev
