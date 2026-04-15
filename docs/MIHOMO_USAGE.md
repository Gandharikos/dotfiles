# Mihomo Usage Guide

## Architecture

**NixOS (Layered Architecture):**

- System layer: `services.mihomo` runs as a system service (provides API and TUN mode)
- User layer: Clash Verge GUI (Home Manager) connects to mihomo API when `my.gui.enable = true`
- Both GUI and headless modes share the same mihomo core service
- WebUI available at `http://localhost:9090/ui`

**Darwin:**

- Clash Verge (Homebrew) includes integrated mihomo core
- No separate system service needed

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

### NixOS (All Modes)

**System Service (always enabled):**

- Runs `services.mihomo` as a systemd service
- Deploys `clash_config` to `/var/lib/mihomo/config.yaml`
- Provides API on port 9090
- Provides WebUI at `http://localhost:9090/ui`
- Handles TUN mode with elevated privileges
- Starts through systemd when `autoStart = true`

**GUI Frontend (when `my.gui.enable = true`):**

- Installs Clash Verge via Home Manager
- Runs as user application (no elevated privileges)
- Connects to local mihomo API (`localhost:9090`)
- Frontend settings in `~/.config/clash-verge/verge.yaml`

### Darwin

- Installs the `clash-verge-rev` Homebrew cask (includes mihomo core)
- Deploys `clash_config` to `~/.config/clash-verge/config.yaml`
- Runs as integrated application
- Does not use separate system service

## Starting and Stopping

### NixOS

**Mihomo Core Service (system-wide):**

```bash
# Control the mihomo service
sudo systemctl stop mihomo
sudo systemctl start mihomo
sudo systemctl restart mihomo
sudo systemctl status mihomo

# View logs
sudo journalctl -u mihomo -f
```

**Clash Verge GUI (user application):**

```bash
# Launch from desktop or run:
clash-verge

# The GUI connects to the mihomo service automatically
```

### Darwin

```bash
# Launch Clash Verge (includes mihomo core)
open -a "Clash Verge"
```

## Config and Logs

### NixOS

**Mihomo Core (system service):**

- Config file: `/var/lib/mihomo/config.yaml` (managed by SOPS)
- Logs: `journalctl -u mihomo`
- WebUI: `http://localhost:9090/ui`

**Clash Verge GUI (user application):**

- Frontend settings: `~/.config/clash-verge/verge.yaml` (managed by Home Manager)
- Connects to mihomo API at `localhost:9090`

### Darwin

- Config file: `~/.config/clash-verge/config.yaml` (includes mihomo core config)

## Examples

### NixOS with GUI

```nix
{
  # Enable GUI and proxy
  my.gui.enable = true;
  my.networking.proxy = {
    enable = true;
    autoStart = true;  # Start mihomo service on boot
  };

  # Clash Verge GUI is automatically enabled via Home Manager
  # when my.gui.enable = true
}
```

### NixOS Headless

```nix
{
  # Headless server
  my.gui.enable = false;
  my.networking.proxy = {
    enable = true;
    autoStart = true;
  };

  # Access via WebUI at http://localhost:9090/ui
}
```

### Darwin

```nix
{
  my.networking.proxy = {
    enable = true;
  };

  # Clash Verge installed via Homebrew with integrated mihomo core
}
```

## Migration

If you were using the older architecture:

### What Changed

**Old Architecture:**

- NixOS GUI: `programs.clash-verge` (system-level, required elevated privileges)
- NixOS Headless: `services.mihomo`
- Separate code paths for GUI vs headless

**New Architecture:**

- NixOS: Always use `services.mihomo` (system service)
- NixOS GUI: Clash Verge in Home Manager (user application) connects to mihomo
- Better privilege separation and security

### Migration Steps

No configuration changes needed! Just rebuild:

```bash
just switch
```

The new architecture:

- Moves Clash Verge from system level to user level (Home Manager)
- Removes the setuid wrapper (`/run/wrappers/bin/clash-verge`)
- Runs Clash Verge as a normal user application
- mihomo core handles all privileged operations (TUN mode)

## Troubleshooting

### Mihomo service failed to start (NixOS)

```bash
# Check service status
sudo systemctl status mihomo

# View recent logs
sudo journalctl -u mihomo -n 50

# Check config file
sudo cat /var/lib/mihomo/config.yaml
```

### WebUI is unavailable

```bash
# Check if mihomo is running
sudo systemctl status mihomo

# Check port binding
sudo lsof -i :9090

# Access WebUI
open http://localhost:9090/ui
```

### Clash Verge GUI can't connect to mihomo

```bash
# Verify mihomo API is accessible
curl http://localhost:9090/

# Check firewall rules
sudo iptables -L -n | grep 9090

# Ensure mihomo service is running
sudo systemctl status mihomo
```

### Port conflict

```bash
# Find what's using port 9090
sudo lsof -i :9090

# If needed, change mihomo port in config
```

### Permission issues

With the new architecture:

- Clash Verge runs as your user (no elevated privileges needed)
- mihomo service runs as `mihomo` user with necessary capabilities
- No setuid wrappers required

## References

- Mihomo Wiki: https://wiki.metacubex.one/
- NixOS Wiki: https://nixos.wiki/wiki/Mihomo
- Clash Verge: https://github.com/clash-verge-rev/clash-verge-rev
