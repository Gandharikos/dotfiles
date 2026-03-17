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
        always-center-single-column = true;
        preset-column-widths = [
          {proportion = 0.33333;}
          {proportion = 0.5;}
          {proportion = 0.66667;}
        ];
        default-column-width = {
          proportion = 0.5;
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
