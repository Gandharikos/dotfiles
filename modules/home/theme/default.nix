{ lib, config, ... }:
let
  inherit (lib.dot) scanPaths;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) str;
  inherit (lib.modules) mkIf;
  inherit (config.dot) theme;
in
{
  imports = scanPaths ./.;

  options.dot.theme.general = {
    transparent = mkEnableOption "Enable tmux transparent" // {
      default = true;
    };
    pad = {
      left = mkOption {
        type = str;
        default = "";
        description = "The left padding of status bar";
      };
      right = mkOption {
        type = str;
        default = "";
        description = "The right padding of status bar";
      };
    };
  };

  config = mkIf (theme != null) {
    home.sessionVariables = {
      COLORSCHEME = theme.colorscheme.slug;
      COLORSCHEME_NAME = theme.default;
    };
  };
}
