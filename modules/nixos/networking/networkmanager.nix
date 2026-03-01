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
  networking.networkmanager = {
    enable = true;
    plugins = with pkgs; optionals isGui [networkmanager-openvpn];
    dns = "systemd-resolved";
    unmanaged =
      [
        "interface-name:br-*"
        "interface-name:rndis*"
      ]
      ++ optionals config.my.services.tailscale.enable ["interface-name:tailscale*"]
      ++ optionals config.my.virtual.podman.enable [
        "interface-name:docker*"
        "interface-name:podman*"
        "interface-name:cni-podman*"
      ]
      ++ optionals config.my.virtual.kvm.enable [
        "interface-name:virbr*"
      ]
      ++ optionals config.my.virtual.waydroid.enable [
        "interface-name:waydroid*"
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
