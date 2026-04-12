{ lib, ... }:
let
  inherit (lib.modules) mkDefault;
in
{
  services = {
    # Note: thermal management (thermald) moved to hardware/power/thermal.nix

    # enable smartd monitoring
    smartd.enable = true;

    # Not using lvm
    lvm.enable = mkDefault false;
  };
}
