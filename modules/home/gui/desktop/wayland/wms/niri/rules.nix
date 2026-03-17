{
  lib,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.lists) singleton;
  inherit (config.my.gui) terminal;
  cfg = config.my.gui.desktop.niri;
in {
  config = mkIf cfg.enable {
    programs.niri.settings = {
      layer-rules = [
        {
          matches = singleton {namespace = "^wallpaper$";};
          place-within-backdrop = true;
        }
      ];
      window-rules = [
        {
          # Default rule for all windows (no opacity = fully opaque)
          matches = [{}];
          open-maximized = false;
          default-column-width = {
            proportion = 1.0 / 2.0;
          };
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
          matches = singleton {title = "^(1Password)$";};
          open-floating = true;
        }
        {
          matches = singleton {title = "^(Picture-in-Picture)$";};
          open-floating = true;
        }
        {
          matches = singleton {title = "^(Spotify( Premium)?)$";};
          open-on-workspace = "9";
        }
        {
          matches = singleton {is-floating = true;};
          border.enable = false;
        }
        {
          matches = singleton {app-id = "Alacritty";};
          inherit (terminal) opacity;
        }
        {
          matches = singleton {app-id = "ghostty";};
          inherit (terminal) opacity;
        }
        {
          matches = singleton {app-id = "wezterm";};
          inherit (terminal) opacity;
        }
        {
          matches = [
            {app-id = "Spotify";}
            {title = "^(Spotify( Premium)?)$";}
          ];
          opacity = 0.85;
        }
      ];
    };
  };
}
