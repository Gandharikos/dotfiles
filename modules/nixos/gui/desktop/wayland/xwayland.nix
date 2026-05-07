{
  config,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (config.dot.gui.desktop.wayland) enable;
in
{
  config = mkIf enable {
    programs.xwayland.enable = true;
  };
}
