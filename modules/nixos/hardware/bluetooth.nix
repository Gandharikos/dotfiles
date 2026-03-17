{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  cfg = config.my.machine;
in
{
  options.my.machine.hasBluetooth = mkEnableOption "Whether the system has bluetooth support";

  config = mkIf cfg.hasBluetooth {
    # enable bluetooth & gui paring tools - blueman
    # or you can use cli:
    # $ bluetoothctl
    # [bluetooth] # power on
    # [bluetooth] # agent on
    # [bluetooth] # default-agent
    # [bluetooth] # scan on
    # ...put device in pairing mode and wait [hex-address] to appear here...
    # [bluetooth] # pair [hex-address]
    # [bluetooth] # connect [hex-address]
    # Bluetooth devices automatically connect with bluetoothctl as well:
    # [bluetooth] # trust [hex-address]
    hardware.bluetooth = {
      enable = true;
      package = pkgs.bluez;
      powerOnBoot = true;
      disabledPlugins = [ "sap" ];
      settings = {
        General = {
          Experimental = true;
          JustWorksPepairing = "always";
          MultiProfile = "multiple";
        };
      };
    };

    # https://wiki.nixos.org/wiki/Bluetooth
    services.blueman.enable = true;
  };
}
