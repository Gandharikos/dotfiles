{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  cfg = config.dot.device;
in
{
  options.dot.device.hasBluetooth = mkEnableOption "Whether the system has bluetooth support";

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
      disabledPlugins = [
        "sap"
        "handsfree"
      ];
      # https://github.com/bluez/bluez/blob/master/src/main.conf
      settings = {
        General = {
          JustWorksRepairing = "always";
          MultiProfile = "multiple";

          # https://wiki.nixos.org/wiki/Bluetooth#Enabling_A2DP_Sink
          Enable = "Source,Sink,Media,Socket";

          # wake the controller up quickly so the headset reconnects with
          # minimal delay instead of waiting on the slow page scan window
          FastConnectable = true;

          # experimental features expose HFP codec negotiation and battery
          # level reporting (BAS) for the headset
          Experimental = true;
          KernelExperimental = true;
        };

        Policy = {
          # reconnect known devices (the headset) automatically on boot/resume
          AutoEnable = true;

          # retry the headset link a few times with backoff after a drop
          ReconnectAttempts = 7;
          ReconnectIntervals = "1, 2, 4, 8, 16, 32, 64";
        };
      };
    };

    boot.kernelModules = [ "btusb" ];

    services.blueman.enable = true;
  };
}
