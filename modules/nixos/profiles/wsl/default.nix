{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf mkDefault mkForce;
  isWsl = config.dot.machine.type == "wsl";
in
{
  imports = [
    inputs.wsl.nixosModules.default
  ];

  config = mkIf isWsl {
    dot = {
      machine = {
        gpu = null;
        cpu = null;
        hasTPM = false;
      };
      boot = {
        loader = "none";
        secureBoot = false;
        tmpOnTmpfs = true;
        enableKernelTweaks = true;
        plymouth.enable = false;

        initrd = {
          enableTweaks = true;
          optimizeCompressor = true;
        };
      };
      gui.enable = mkDefault false;
      game.enable = mkForce false;
      security = {
        enable = false;
        auditd.enable = true;
      };
      virtual = {
        enable = mkForce false;
        docker.enable = config.dot.gui.enable;
      };
      services.oomd.enable = mkForce false;
      persistence.enable = mkForce false;
      # TODO: so many things rely on yubikey, so It should enable no WSL too
      yubikey.enable = mkForce false;
    };
    hm.dot = {
      fastfetch.startOnLogin = mkDefault false;
    };
    wsl = {
      enable = true;
      wslConf = {
        automount.root = "/mnt";
        interop.appendWindowsPath = false;
        network.gnerateHosts = false;
      };
      defaultUser = config.dot.name;
      startMenuLaunchers = true;

      interop = {
        includePath = false;
        register = true;
      };

      # enable integration with Docker Desktop (needed to be installed)
      docker-desktop.enable = config.dot.gui.enable;
    };
    networking = {
      networkmanager.enable = mkForce false;
      nftables.enable = mkForce false;
      extraHosts = mkForce "";
    };
    # other
    services = {
      # that's not make sense on WSL
      smartd.enable = mkForce false;
      thermald.enable = mkForce false;
      resolved.enable = mkForce false;
      earlyoom.enable = mkForce false;
    };

    environment = {
      variables.BROWSER = mkForce "wsl-open";
      systemPackages = [ pkgs.wsl-open ];
    };
  };
}
