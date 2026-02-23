{
  lib,
  config,
  ...
}: let
  cfg = config.my.networking.wirelessBackend;
  inherit (lib.options) mkOption;
  inherit (lib.types) enum;
in {
  options.my.networking = {
    # use wpa_supplicant or iwd, use wpa_supplicant until iwd is stable
    wirelessBackend = mkOption {
      type = enum [
        "wpa_supplicant"
        "iwd"
      ];
      default = "wpa_supplicant";
      description = ''
        Specify the Wi-Fi backend used for the device.
        Currently supported are {option}`wpa_supplicant` or {option}`iwd` (experimental).
      '';
    };
  };

  config = {
    # enable wireless database, it helps keeping wifi speedy
    hardware.wirelessRegulatoryDatabase = true;

    networking.wireless = {
      # wpa_supplicant
      enable = cfg == "wpa_supplicant";
      userControlled = true;
      allowAuxiliaryImperativeNetworks = true;

      extraConfig = ''
        update_config=1
      '';

      # iwd
      iwd = {
        enable = cfg == "iwd";

        settings = {
          Settings.AutoConnect = true;

          General = {
            EnableNetworkConfiguration = true;
            RoamRetryInterval = 15;
          };

          Network = {
            EnableIPv6 = true;
            RoutePriorityOffset = 300;
          };
        };
      };
    };
  };
}
