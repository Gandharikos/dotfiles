{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.lists) singleton;
  browserAppIds = [
    "zen"
    "firefox"
    "org.mozilla.firefox"
    "google-chrome"
    "google-chrome-stable"
  ];
  browserMatches = builtins.map (appId: { "app-id" = "^${appId}$"; }) browserAppIds;
  pipTitle = "^(Picture-in-Picture|Picture in picture)$";
  cfg = config.my.gui.desktop.niri;
in
{
  config = mkIf cfg.enable {
    programs.niri.settings = {
      layer-rules = [
        {
          matches = singleton { namespace = "^wallpaper$"; };
          place-within-backdrop = true;
        }
      ];
      window-rules = [
        {
          geometry-corner-radius = {
            top-left = 12.0;
            top-right = 12.0;
            bottom-left = 12.0;
            bottom-right = 12.0;
          };
          clip-to-geometry = true;
          draw-border-with-background = false;
        }
        {
          matches = [
            { title = "^(1Password)$"; }
            { title = "^(Bitwarden)$"; }
            { app-id = "^(Bitwarden)$"; }
          ];
          open-floating = true;
        }
        {
          matches = browserMatches;
          excludes = singleton { title = pipTitle; };
          open-maximized = true;
        }
        {
          matches = singleton { title = pipTitle; };
          open-floating = true;
          open-focused = false;
          default-floating-position = {
            x = 24;
            y = 24;
            relative-to = "bottom-right";
          };
          default-column-width = {
            proportion = 0.3;
          };
          default-window-height = {
            proportion = 0.3;
          };
        }
        {
          matches = singleton { title = "^(Spotify( Premium)?)$"; };
          open-on-workspace = "9";
        }
        {
          matches = singleton { is-floating = true; };
          border.enable = false;
        }
        {
          matches = [
            { app-id = "Spotify"; }
            { title = "^(Spotify( Premium)?)$"; }
          ];
          opacity = 0.85;
        }
        {
          matches = singleton { "app-id" = "^(dev\\.zed\\.Zed|zed)$"; };
          opacity = 0.88;
        }
      ];
    };
  };
}
