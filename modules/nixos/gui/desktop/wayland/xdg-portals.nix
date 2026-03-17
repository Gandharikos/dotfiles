{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf mkDefault;
  cfg = config.my.gui.desktop;
  portal =
    if cfg.default == "hyprland" then
      "hyprland"
    else if cfg.default == "niri" then
      "gnome"
    else
      "wlr";
  extraPortals =
    if cfg.default == "niri" then
      [ pkgs.xdg-desktop-portal-gnome ]
    else
      [ pkgs.xdg-desktop-portal-wlr ];
  wlrEnable = cfg.default != "niri";
  inherit (cfg.wayland) enable;
in
{
  config = mkIf enable {
    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      inherit extraPortals;
      config.common = {
        default = "*";

        # for flameshot to work
        # https://github.com/flameshot-org/flameshot/issues/3363#issuecomment-1753771427
        "org.freedesktop.impl.portal.Screencast" = [ "${portal}" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "${portal}" ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      };
      wlr = {
        enable = mkDefault wlrEnable;
        settings = {
          screencast = {
            max_fps = 60;
            chooser_type = "simple";
            chooser_cmd = "${getExe pkgs.slurp} -f %o -or";
          };
        };
      };
    };
  };
}
