{
  lib,
  config,
  ...
}:
let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) enum;
  inherit (config) dot;
in
{
  options.dot.theme.tokyonight = {
    enable = mkEnableOption "Tokyonight theme" // {
      default = dot.admin.theme.tokyonight.enable;
    };

    style = mkOption {
      type = enum [
        "night"
        "storm"
        "day"
        "moon"
      ];
      default = dot.admin.theme.tokyonight.style;
      description = "The style of tokyonight";
    };
  };
}
