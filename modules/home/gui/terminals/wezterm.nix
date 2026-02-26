{
  lib,
  config,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.desktop.apps.wezterm;
in {
  options.my.desktop.apps.wezterm = {
    enable =
      mkEnableOption "wezterm"
      // {
        default = config.my.terminal.default == "wezterm";
      };
  };

  # TODO: Setup wezterm config use nix for more flexibility
  config = mkIf cfg.enable {
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
