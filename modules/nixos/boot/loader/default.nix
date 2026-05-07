{ lib, ... }:
let
  inherit (lib.options) mkOption;
  inherit (lib.modules) mkForce;
  inherit (lib.types) enum;
in
{
  imports = lib.dot.scanPaths ./.;
  options.dot.boot.loader = mkOption {
    type = enum [
      "none"
      "grub"
      "systemd-boot"
    ];
    default = "grub";
    description = "The boot loader to use.";
  };
  config = {
    # shared config between bootloaders
    # they are set unless system.boot.loader != none
    boot.loader = {
      # if set to 0, space needs to be held to get the boot menu to appear
      timeout = mkForce 2;

      # copy boot files to /boot so that /nix/store is not required to boot
      # it takes up more space but it makes my messups a bit safer
      generationsDir.copyKernels = true;

      # we need to allow installation to modify EFI variables
      efi.canTouchEfiVariables = true;
    };
  };
}
