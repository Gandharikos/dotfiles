{
  lib,
  config,
  ...
}: let
  cfg = config.my.networking;
  inherit (lib.options) mkOption;
  inherit (lib.types) enum;
  inherit (lib.modules) mkIf;
in {
  options.my.networking = {
    # use wpa_supplicant or iwd, use wpa_supplicant until iwd is stable
    backend = mkOption {
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
    networking.wireless.iwd = mkIf (cfg.backend == "iwd") {
      enable = true;
      settings = {
        General.RoamRetryInterval = 15;
        Network.EnableIpv6 = cfg.enableIPV6;
      };
    };
  };
}
