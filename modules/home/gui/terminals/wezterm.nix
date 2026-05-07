{
  lib,
  config,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (config.dot) gui;
  cfg = config.dot.gui.apps.wezterm;
  enable = gui.enable && cfg.enable;
in
{
  options.dot.gui.apps.wezterm = {
    enable = mkEnableOption "wezterm" // {
      default = config.dot.gui.terminal.default == "wezterm";
    };
  };

  # TODO: Setup wezterm config use nix for more flexibility
  config = mkIf enable {
    programs.wezterm = {
      enable = true;
    };

    xdg.configFile."wezterm" = {
      recursive = true;
      source = lib.dot.relativeToConfig "wezterm";
    };
  };
}
