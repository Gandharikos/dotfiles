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
      default = dot.theme.default == "tokyonight";
    };

    style = mkOption {
      type = enum [
        "night"
        "storm"
        "day"
        "moon"
      ];
      default = "moon";
      description = "The style of tokyonight";
    };
  };
}
