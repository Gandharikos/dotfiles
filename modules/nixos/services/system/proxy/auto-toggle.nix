{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.my.services.proxy;
  inherit (lib.modules) mkIf;

  proxy-toggle-script = pkgs.writeShellScript "proxy-auto-toggle" ''
    #!${pkgs.runtimeShell}
    set -e

    # Only act on the 'up' event.
    if [ "$2" != "up" ]; then
        exit 0
    fi

    # Add necessary commands to PATH
    export PATH=${lib.makeBinPath [pkgs.networkmanager pkgs.systemd pkgs.util-linux]}

    # Get runtime info
    # Note: SSID will be empty if connected via Ethernet.
    SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
    TZ=$(timedatectl show --property=Timezone --value)

    # Core logic: if in China (Shanghai TZ) and not at home (not Freeland)
    if [ "$TZ" = "Asia/Shanghai" ] && [ "$SSID" != "Freeland" ]; then
      echo "Auto-Proxy: Starting proxy services (mihomo, dae)..."
      systemctl start mihomo.service dae.service || true
    else
      # At home (SSID is Freeland), not in China (TZ is not Shanghai), or on Ethernet (SSID is empty)
      echo "Auto-Proxy: Stopping proxy services (mihomo, dae)..."
      systemctl stop mihomo.service dae.service || true
    fi
  '';
in {
  # This configuration block is only active if proxies are enabled at build-time
  # (which defaults to true only if timezone is Asia/Shanghai).
  config = mkIf (cfg.enable && config.networking.networkmanager.enable) {
    # Add the dispatcher script to handle the logic.
    networking.networkmanager.dispatcherScripts = [
      {
        source = proxy-toggle-script;
        type = "basic";
      }
    ];
  };
}
