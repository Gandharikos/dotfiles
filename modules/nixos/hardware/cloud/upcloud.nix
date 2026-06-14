{ config, lib, ... }:
let
  inherit (lib.modules) mkDefault mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) str;
  cfg = config.dot.profiles.upcloud;
in
{
  options.dot.profiles.upcloud = {
    enable = mkEnableOption "UpCloud profile";
    bootDevice = mkOption {
      type = str;
      default = "/dev/vda";
      description = "Disk device where GRUB should be installed.";
    };
  };

  config = mkIf cfg.enable {
    dot = {
      device = {
        type = mkDefault "server";
        cpu = mkDefault "vm-intel";
        gpu = mkDefault null;
      };
      boot = {
        loader = mkDefault "grub";
        grub.devices = mkDefault [ cfg.bootDevice ];
      };
    };
  };
}
