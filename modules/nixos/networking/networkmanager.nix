{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib.lists) optionals;
  isGui = config.dot.gui.enable;
  # isServer = config.dot.machine.machine == "server";
in
{
  networking.networkmanager = {
    enable = true;
    plugins = with pkgs; optionals isGui [ networkmanager-openvpn ];
    dns = "systemd-resolved";
    unmanaged = [
      "interface-name:br-*"
      "interface-name:rndis*"
    ]
    ++ optionals config.dot.networking.tailscale.enable [ "interface-name:tailscale*" ]
    ++ optionals config.dot.virtual.podman.enable [
      "interface-name:docker*"
      "interface-name:podman*"
      "interface-name:cni-podman*"
    ]
    # ++ optionals config.dot.virtual.kvm.enable [
    #   "interface-name:virbr*"
    # ]
    ++ optionals config.dot.virtual.waydroid.enable [
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
