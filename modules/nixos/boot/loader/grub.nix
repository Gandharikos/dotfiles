{
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf mkDefault;
  inherit (lib.options) mkOption;
  inherit (lib.types) listOf str;
  cfg = config.dot.boot;
in
{
  imports = [
    inputs.dedsec-grub-theme.nixosModule
  ];

  options.dot.boot.grub = {
    devices = mkOption {
      type = listOf str;
      default = [ "nodev" ];
      description = "The devices to install the GRUB bootloader to. Use nodev to generate GRUB configuration without installing to a disk.";
    };
    style = mkOption {
      type = str;
      default = "wrench";
      description = "The style to use for the GRUB bootloader.";
    };
  };

  config = mkIf (cfg.loader == "grub") {
    boot.loader.grub = {
      enable = mkDefault true;
      useOSProber = mkDefault true;
      efiSupport = true;
      enableCryptodisk = mkDefault false;
      devices = mkDefault cfg.grub.devices;
      dedsec-theme = {
        enable = true;
        inherit (cfg.grub) style;
        icon = "color";
        resolution = "1440p";
      };
    };
  };
}
