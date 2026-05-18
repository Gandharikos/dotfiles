{
  lib,
  config,
  osConfig,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.gui.apps.wezterm;
  enable = osConfig.dot.gui.enable && cfg.enable;
in
{
  options.my.gui.apps.wezterm = {
    enable = mkEnableOption "wezterm" // {
      default = config.my.gui.terminal.default == "wezterm";
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
