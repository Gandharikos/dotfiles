{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.herdr;
in
{
  options.my.herdr = {
    enable = mkEnableOption "herdr terminal workspace manager for AI coding agents" // {
      default = config.my.mux.default == "herdr";
    };
  };

  config = mkIf cfg.enable {
    programs.herdr = {
      enable = true;
      package = pkgs.herdr;
      settings = {
        theme = {
          name = "tokyo-night";
        };

        terminal = {
          shell_mode = "auto";
          new_cwd = "follow";
        };

        update = {
          channel = "stable";
          version_check = false;
          manifest_check = true;
        };

        ui = {
          mouse_capture = true;
          pane_borders = true;
          pane_gaps = true;
          accent = "blue";
          toast = {
            delivery = "terminal";
          };
        };

        experimental = {
          pane_history = false;
        };
      };
    };
  };
}
