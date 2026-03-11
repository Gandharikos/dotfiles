{
  lib,
  config,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (config.my) gui;
  cfg = config.my.gui.apps.wezterm;
  enable = gui.enable && cfg.enable;
in {
  options.my.gui.apps.wezterm = {
    enable =
      mkEnableOption "wezterm"
      // {
        default = config.my.gui.terminal.default == "wezterm";
      };
  };

  # TODO: Setup wezterm config use nix for more flexibility
  config = mkIf enable {
    programs.wezterm = {enable = true;};

    xdg.configFile."wezterm" = {
      recursive = true;
      source = lib.my.relativeToConfig "wezterm";
    };

    home.persistence."/persist".directories = [
      ".cache/wezterm"
      ".local/share/wezterm"
    ];
  };
}
