{
  lib,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe;
  cfg = config.my.keyboard.kanata;
  kanata' = getExe cfg.package;
in {
  config = mkIf cfg.enable {
    # Install required packages
    environment.systemPackages = [
      cfg.package
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
            kanata'
            "--cfg"
            (toString cfg.configFile)
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
  };
}
