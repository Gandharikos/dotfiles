{
  lib,
  config,
  ...
}:
let
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.modules) mkIf mkForce;
  cfg = config.dot.profiles.headless;
in
{
  config = mkIf cfg.enable {
    xdg = mapAttrs (_: mkForce) {
      sounds.enable = false;
      mime.enable = false;
      menus.enable = false;
      icons.enable = false;
      autostart.enable = false;
    };
  };
}
