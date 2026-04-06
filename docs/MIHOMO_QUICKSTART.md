# Mihomo Quick Start

## 🎯 Design Goals

- **System-level service**: NixOS uses systemd, Darwin uses launchd daemons
- **No auto-start by default**: manual control works better for occasional use
- **GUI-first**: Clash Verge is the recommended way to manage the proxy

## 📦 Quick Configuration

### NixOS

```nix
# hosts/sigurd/config.nix or another NixOS host
{
  my.networking.proxy = {
    enable = true;
    enableGui = true;  # Default, can be omitted
    # autoStart = false;   # Default, can be omitted
    # enableWebui = true;  # Default, can be omitted
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
    enableWebui = false;   # The GUI is usually enough
  };
}
```

Before enabling the module, make sure `secrets/services/mihomo.yaml` already contains an encrypted
`mihomo_config`.

## 🚀 Enable It

1. **Add the configuration** shown above.

2. **Rebuild the system**:

   ```bash
   # NixOS
   sudo nixos-rebuild switch --flake .

   # Darwin
   darwin-rebuild switch --flake .

   # Or via just
   just switch
   ```

3. **Launch the GUI**:
   - macOS: open Clash Verge from Launchpad or run `clash-verge`
   - Linux: open Clash Verge from the app launcher or run `clash-verge`

4. **Control the proxy manually**:
   - When needed: open the GUI and click "Start" or "Connect"
   - When not needed: click "Stop" or "Disconnect"

## 🎨 GUI Toggle

```nix
enableGui = true;   # Default: install Clash Verge
enableGui = false;  # CLI/WebUI only
```

## 📍 File Locations

### NixOS

- Config: `/var/lib/mihomo/config.yaml`
- Logs: `sudo journalctl -u mihomo`

### Darwin

- Config: `~/.config/mihomo/config.yaml`
- Logs: `/var/log/mihomo.log`

## 🔧 Manual Service Management

### NixOS

```bash
sudo systemctl start mihomo
sudo systemctl stop mihomo
sudo systemctl status mihomo
```

### Darwin

```bash
sudo launchctl load /Library/LaunchDaemons/com.mihomo.proxy.plist
sudo launchctl unload /Library/LaunchDaemons/com.mihomo.proxy.plist
```

## 💡 Common Setups

### Scenario 1: Use it only when needed

```nix
{
  my.networking.proxy = {
    enable = true;
    enableGui = true;
    autoStart = false;
  };
}
```

Use it by opening the GUI when needed and closing it when done.

### Scenario 2: Headless or server-style setup

```nix
{
  my.networking.proxy = {
    enable = true;
    enableGui = false;
    enableWebui = true;
  };
}
```

Use the WebUI at `http://localhost:9090/ui`.

### Scenario 3: Use the encrypted SOPS config

```nix
{
  my.networking.proxy = {
    enable = true;
    enableGui = true;
  };
}
```

Requirement: define `mihomo_config` in `secrets/services/mihomo.yaml`.

## 🎁 Result

You now have:

- A shared Mihomo configuration path for NixOS and Darwin
- Fully manual control over proxy startup and shutdown
- GUI-based node and rule management through Clash Verge
- On-demand usage without background update scripts

## 📚 More

See `docs/MIHOMO_USAGE.md` for the full guide.
