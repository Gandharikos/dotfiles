{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf mkMerge;
  inherit (config.dot.theme) cursor;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  hyprlandEnabled = config.dot.gui.desktop.hyprland.enable;
  enable = cursor != null && config.dot.gui.enable && isLinux;
in
{
  config = mkIf enable (mkMerge [
    {
      home.pointerCursor = {
        inherit (cursor) name package size;
        gtk.enable = true;
        x11.enable = true;
      };
    }
    (mkIf (hyprlandEnabled && cursor.hyprcursor != null) {
      home = {
        packages = [ cursor.hyprcursor.package ];
        sessionVariables = {
          HYPRCURSOR_THEME = cursor.hyprcursor.name;
          HYPRCURSOR_SIZE = toString cursor.size;
        };
      };
    })
  ]);
}
