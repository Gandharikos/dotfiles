{ config, lib, ... }:
let
  inherit (lib.modules) mkDefault mkForce mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) nullOr str;
  cfg = config.dot.profiles.hetzner;
in
{
  options.dot.profiles.hetzner = {
    enable = mkEnableOption "Hetzner Cloud profile";
    bootDevice = mkOption {
      type = str;
      default = "/dev/sda";
      description = "Disk device where GRUB should be installed.";
    };
    macAddress = mkOption {
      type = nullOr str;
      default = null;
      description = "Optional MAC address to rename to the configured interface.";
    };
  };

  config = mkIf cfg.enable {
    dot = {
      device = {
        type = mkDefault "server";
        cpu = mkDefault "vm-amd";
        gpu = mkDefault null;
        hasBluetooth = false;
        hasPrinter = false;
        hasTPM = false;
      };
      boot = {
        loader = "grub";
        secureBoot = false;
        tmpOnTmpfs = false;
        grub.devices = [ cfg.bootDevice ];
        plymouth.enable = mkForce false;
      };
    };
    boot.loader = {
      efi.canTouchEfiVariables = lib.mkForce false;
      grub = {
        dedsec-theme.enable = lib.mkForce false;
      };
    };

  };
}
