{
  lib,
  config,
  ...
}:
let
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) enum;
  inherit (config) my;
in
{
  options.my.theme.catppuccin = {
    enable = mkEnableOption "Catppuccin theme" // {
      default = my.theme.default == "catppuccin";
    };

    flavor = mkOption {
      type = enum [
        "latte"
        "frappe"
        "macchiato"
        "mocha"
      ];
      default = "mocha";
      description = "The Catppuccin flavor to use.";
    };

    accent = mkOption {
      type = enum [
        "blue"
        "flamingo"
        "green"
        "lavender"
        "maroon"
        "mauve"
        "peach"
        "pink"
        "red"
        "rosewater"
        "sapphire"
        "sky"
        "teal"
        "yellow"
      ];
      default = "mauve";
      description = "The Catppuccin accent color to use.";
    };
  };
}
