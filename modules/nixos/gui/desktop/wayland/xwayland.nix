{
  config,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (config.my.gui.desktop.wayland) enable;
in
{
  config = mkIf enable {
    programs.xwayland.enable = true;
  };
}
