{ lib, ... }:
let
  inherit (lib.options) mkOption;
  inherit (lib.types) enum nullOr;
  inherit (lib.my) scanPaths;
in
{
  imports = scanPaths ./.;
  # hardware
  options.my.machine = {
    type = mkOption {
      type = enum [
        "workstation"
        "server"
        "laptop"
        "desktop"
        "mobile"
        "vm"
        "wsl"
      ];
      default = "laptop";
      description = "The architecture of the system";
    };
    gpu = mkOption {
      type = nullOr (enum [
        "intel"
        "nvidia"
        "amd"
        "hybrid-nv"
      ]);
      default = null;
      description = "The GPU of the system";
    };
    cpu = mkOption {
      type = nullOr (enum [
        "intel"
        "amd"
        "vm-intel"
        "vm-amd"
      ]);
      default = null;
      description = "The CPU of the system";
    };
  };
}
