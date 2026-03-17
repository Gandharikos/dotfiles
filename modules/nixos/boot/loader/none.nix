{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf mkForce;
  cfg = config.my.boot;
in
{
  config = mkIf (cfg.loader == "none") {
    boot.loader = {
      grub.enable = mkForce false;
      systemd-boot.enable = mkForce false;
    };
  };
}
