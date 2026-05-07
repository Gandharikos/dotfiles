{ config, ... }:
let
  cfg = config.dot.networking;
in
{
  # enable wireless database, it helps keeping wifi speedy
  hardware.wirelessRegulatoryDatabase = true;
  networking.wireless = {
    # wpa_supplicant
    userControlled.enable = true;
    allowAuxiliaryImperativeNetworks = true;
    extraConfig = ''
      update_config=1
    '';
    iwd.settings = {
      Settings.AutoConnect = true;
      General = {
        EnableNetworkConfiguration = true;
        RoamRetryInterval = 15;
      };
      Network.EnableIpv6 = cfg.enableIPv6;
    };
  };
}
