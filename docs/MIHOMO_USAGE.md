# Mihomo Usage Guide

## Architecture

- **NixOS**: system-level service via systemd
- **Darwin**: system-level service via launchd daemons
- **Default behavior**: no auto-start, manual control through the GUI or service manager

## Quick Configuration

### NixOS

```nix
# hosts/sigurd/config.nix or another NixOS host
{
  my.networking.proxy = {
    enable = true;
    enableGui = true;    # Default, can be omitted
    autoStart = false;   # Default
    enableWebui = true;  # Optional
  };
}
```

### Darwin (macOS)

```nix
# hosts/eir/config.nix or hosts/tyr/config.nix
{
  my.networking.proxy = {
    enable = true;
    enableGui = true;      # Default, can be omitted
    autoStart = false;
    enableWebui = false;   # The GUI is usually enough
  };
}
```

Prerequisite: `secrets/services/mihomo.yaml` must already contain an encrypted `mihomo_config`.

## Option Reference

### `enable`

- Type: `boolean`
- Default: `false`
- Meaning: enable Mihomo integration

### `enableGui`

- Type: `boolean`
- Default: `true`
- Meaning: install the Clash Verge GUI client

### `enableWebui`

- Type: `boolean`
- Default: `true`
- Meaning: enable the WebUI package (`metacubexd`)

### `autoStart`

- Type: `boolean`
- Default: `false`
- Meaning: start the Mihomo service automatically at boot

## Using the GUI

### 1. Enable the GUI

With `enableGui = true`, rebuild the system and launch Clash Verge.

**NixOS**:

```bash
clash-verge
```

**Darwin**:

```bash
open -a "Clash Verge"
```

Typical flow:

1. Open the GUI application.
2. Import the config or confirm `mihomo_config` has already been deployed.
3. Click "Start" or "Connect" when you need the proxy.
4. Click "Stop" or "Disconnect" when you do not.

### 2. Use the WebUI

If `enableWebui = true`:

1. Start the Mihomo service manually.
2. Open `http://localhost:9090/ui`.

## Manual Service Management

### NixOS

```bash
sudo systemctl start mihomo
sudo systemctl stop mihomo
sudo systemctl restart mihomo
sudo systemctl status mihomo
sudo journalctl -u mihomo -f
sudo systemctl enable mihomo
```

### Darwin

```bash
sudo launchctl load /Library/LaunchDaemons/com.mihomo.proxy.plist
sudo launchctl unload /Library/LaunchDaemons/com.mihomo.proxy.plist
sudo launchctl list | grep mihomo
tail -f /var/log/mihomo.log
tail -f /var/log/mihomo-error.log
```

## Using the SOPS Secret

The module now expects a full encrypted Mihomo config file instead of a subscription URL.

```nix
{
  my.networking.proxy = {
    enable = true;
    enableGui = true;
    autoStart = false;
    enableWebui = true;
  };

  # Ensure `mihomo_config` exists in secrets/services/mihomo.yaml
}
```

## Config File Locations

### NixOS

- Config file: `/var/lib/mihomo/config.yaml`
- Logs: `journalctl -u mihomo`

### Darwin

- Config file: `~/.config/mihomo/config.yaml`
- Logs: `/var/log/mihomo.log` and `/var/log/mihomo-error.log`

## WebUI Access

If WebUI is enabled:

- URL: `http://localhost:9090/ui`
- Port: `9090`

## Example Configurations

### Example 1: NixOS + encrypted config + GUI

```nix
# hosts/sigurd/config.nix
{
  my.networking.proxy = {
    enable = true;
    enableGui = true;
    autoStart = false;
    enableWebui = true;
  };
}
```

### Example 2: NixOS + WebUI only

```nix
{
  my.networking.proxy = {
    enable = true;
    enableGui = false;
    autoStart = false;
    enableWebui = true;
  };
}
```

### Example 3: Darwin + GUI

```nix
# hosts/eir/config.nix
{
  my.networking.proxy = {
    enable = true;
    enableGui = true;
    autoStart = false;
    enableWebui = false;
  };
}
```

### Example 4: Auto-start enabled

```nix
{
  my.networking.proxy = {
    enable = true;
    enableGui = true;
    autoStart = true;
    enableWebui = false;
  };
}
```

## Recommended Workflow

### Daily use

1. Configure:

   ```nix
   my.networking.proxy = {
     enable = true;
     enableGui = true;
   };
   ```

2. Rebuild: `sudo nixos-rebuild switch` or `darwin-rebuild switch --flake .`

3. Use:
   - Open Clash Verge when you need the proxy
   - Disconnect when finished
   - Switch nodes inside the GUI

### WebUI-only use

1. Configure:

   ```nix
   my.networking.proxy = {
     enable = true;
     enableGui = false;
     enableWebui = true;
   };
   ```

2. Start Mihomo: `sudo systemctl start mihomo`

3. Open: `http://localhost:9090/ui`

## Troubleshooting

### GUI cannot find the Mihomo binary

Check whether Mihomo is in `PATH`:

```bash
which mihomo
```

Expected output:

- NixOS: `/run/current-system/sw/bin/mihomo`
- Darwin: `/nix/var/nix/profiles/default/bin/mihomo`

### Service failed to start

Check logs:

```bash
# NixOS
sudo journalctl -u mihomo -n 50

# Darwin
tail -50 /var/log/mihomo-error.log
```

### Port conflict

Mihomo uses port `9090` by default. Check for conflicts with:

```bash
sudo lsof -i :9090
```

## Relation to the Old Setup

- `my.networking.proxy.enable` controls whether proxy-related integration is enabled
- `my.networking.proxy.backend = "mihomo"` selects Mihomo as the backend
- On both NixOS and Darwin, enabling `my.networking.proxy` activates the platform-specific Mihomo
  integration

## Migration

If you were using the previous setup:

1. Enable the module:

   ```nix
   my.networking.proxy.enable = true;
   ```

2. Configure the GUI and static config:

   ```nix
   my.networking.proxy = {
     enable = true;
     enableGui = true;
   };
   ```

3. Rebuild the system.

4. Verify by opening the GUI or checking service state.

## References

- Mihomo Wiki: https://wiki.metacubex.one/
- NixOS Wiki: https://nixos.wiki/wiki/Mihomo
- Clash Verge: https://github.com/clash-verge-rev/clash-verge-rev
