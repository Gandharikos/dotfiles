{
  lib,
  config,
  ...
}: let
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.modules) mkIf mkForce;
  isHeadless = !config.my.gui.enable;
in {
  config = mkIf isHeadless {
    xdg = mapAttrs (_: mkForce) {
      sounds.enable = false;
      mime.enable = false;
      menus.enable = false;
      icons.enable = false;
      autostart.enable = false;
    };
  };
}
