{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (config.my.theme) cursor;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  enable = cursor != null && config.my.gui.enable && isLinux;
in {
  config = mkIf enable {
    # If your theme for mouse cursor, icons or windows don't load correctly,
    # try setting them with home.pointerCursor and gtk.theme,
    # which enable a bunch of compatibility options that should make the theme load in all situations.
    home = {
      sessionVariables = {
        XCURSOR_THEME = cursor.name;
        XCURSOR_SIZE = toString cursor.size;
      };
      pointerCursor = {
        inherit (cursor) name package size;
        gtk.enable = true;
        x11.enable = true;
        hyprcursor.enable = true;
      };
    };
    gtk.cursorTheme = {
      inherit (cursor) name package size;
    };
    xdg.dataFile."icon/${cursor.name}".source = "${cursor.package}/share/icons/${cursor.name}";
  };
}
