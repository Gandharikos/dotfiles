{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.dot.services.kanata;
  # Use a stable executable path so launchd/TCC rules do not break across nix store hash changes.
  kanataBin = "/run/current-system/sw/bin/kanata";
  kanataConfig = (import ../common/dot/keyboard/kanata.nix { inherit lib pkgs; }).mkKanataConfig { };
  configFile = pkgs.writeText "kanata.kbd" kanataConfig;
in
{
  config = mkIf cfg.enable {
    # Install required packages
    environment.systemPackages = [
      pkgs.kanata-with-cmd
    ];

    # Launch daemon for the Virtual HID Device
    launchd.daemons = {
      karabiner-virtualhid = {
        serviceConfig = {
          Label = "org.pqrs.Karabiner-DriverKit-VirtualHIDDevice";
          KeepAlive = true;
          RunAtLoad = true;
          StandardOutPath = "/var/log/karabiner-virtualhid.log";
          StandardErrorPath = "/var/log/karabiner-virtualhid-error.log";
          Program = "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon";
          WorkingDirectory = "/tmp";
          # Add some safety measures
          ThrottleInterval = 30; # Prevent rapid restarts
          Nice = -5; # Give high priority to the virtual HID device
        };
      };
      kanata = {
        serviceConfig = {
          ProgramArguments = [
            kanataBin
            "--cfg"
            (toString configFile)
          ];
          Label = "org.nixos.kanata";
          KeepAlive = true;
          RunAtLoad = true;
          StandardOutPath = "/var/log/kanata.log";
          StandardErrorPath = "/var/log/kanata-error.log";
          WorkingDirectory = "/tmp";
          ThrottleInterval = 30;
          Nice = -5;
        };
      };
    };

    # karabiner_grabber and kanata cannot reliably grab the same keyboard devices at once.
    # system.activationScripts.kanata-disable-karabiner-grabber.text = ''
    #   launchctl bootout system/org.pqrs.service.daemon.karabiner_grabber >/dev/null 2>&1 || true
    #   launchctl disable system/org.pqrs.service.daemon.karabiner_grabber >/dev/null 2>&1 || true
    # '';
  };
}
