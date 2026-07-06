{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkDefault mkForce mkIf;
  isVm = config.dot.device.type == "vm";
in
{
  config = mkIf isVm {
    dot = {
      profiles.minimal.enable = mkDefault true;

      boot = {
        loader = mkDefault "none";
        secureBoot = mkDefault false;
        tmpOnTmpfs = mkDefault false;
        enableKernelTweaks = mkDefault false;
        plymouth.enable = mkDefault false;

        initrd = {
          enableTweaks = mkDefault false;
          optimizeCompressor = mkDefault false;
        };
      };

      device = {
        gpu = mkDefault null;
        hasBluetooth = mkDefault false;
        hasPrinter = mkDefault false;
        hasTPM = mkDefault false;
      };

      gui.enable = mkForce false;

      keyboard = {
        layout = mkDefault "qwerty";
        backend = mkDefault null;
      };

      networking = {
        enableIPv6 = mkDefault false;
        tailscale.enable = mkForce false;
        vpn.enable = mkForce false;
      };

      security = {
        enable = mkForce false;
        auditd.enable = mkForce false;
        apparmor.enable = mkForce false;
        clamav.enable = mkForce false;
      };

      services.zram.enable = mkDefault true;
    };

    environment.systemPackages = with pkgs; [
      curl
      git
      jq
      just
    ];

    services.smartd.enable = mkForce false;
  };
}
