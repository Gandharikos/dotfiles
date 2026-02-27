{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib.lists) optionals;
  isGui = config.my.desktop.enable;
  # isServer = config.my.machine.machine == "server";
in {
  environment.systemPackages = optionals isGui [
    pkgs.networkmanagerapplet
  ];

  networking.networkmanager = {
    enable = true;
    plugins = optionals isGui [pkgs.networkmanager-openvpn];
    dns = "systemd-resolved";
    unmanaged = [
      "interface-name:tailscale*"
      "interface-name:br-*"
      "interface-name:rndis*"
      "interface-name:docker*"
      "interface-name:virbr*"
      "interface-name:vboxnet*"
      "interface-name:waydroid*"
      "type:bridge"
    ];

    wifi = {
      # this can be iwd or wpa_supplicant, use wpa_s until iwd support is stable
      backend = "iwd";

      # The below is disabled as my uni hated me for it
      # macAddress = "random"; # use a random mac address on every boot, this can scew with static ip
      powersave = true;

      # MAC address randomization of a Wi-Fi device during scanning
      # This is a privacy feature that prevents tracking of devices by their MAC address
      scanRandMacAddress = true;
    };

    # ethernet.macAddress = mkIf isServer "random";
  };

  programs.nm-applet.enable = isGui;
}
