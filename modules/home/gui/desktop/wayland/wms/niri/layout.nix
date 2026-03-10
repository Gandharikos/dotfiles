{
  lib,
  config,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.my.gui.desktop.niri;
in {
  config = mkIf cfg.enable {
    programs.niri.settings = {
      layout = {
        shadow.enable = true;
        center-focused-column = "never";
        preset-column-widths = [
          {proportion = 1.0 / 3.0;}
          {proportion = 1.0 / 2.0;}
          {proportion = 2.0 / 3.0;}
          {proportion = 4.0 / 5.0;}
        ];
        default-column-width = {
          proportion = 4.0 / 5.0;
        };
        focus-ring = {
          enable = true;
          width = 2;
        };
        border = {
          enable = false;
          width = 1;
        };
      };
    };
  };
}
