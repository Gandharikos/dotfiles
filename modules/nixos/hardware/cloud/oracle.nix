{ config, lib, ... }:
let
  inherit (lib.modules) mkForce mkIf;
  inherit (lib.options) mkEnableOption;
in
{
  options.dot.profiles.oracle.enable = mkEnableOption "Oracle Cloud profile";

  config = mkIf config.dot.profiles.oracle.enable {
    services.thermald.enable = mkForce false;
  };
}
