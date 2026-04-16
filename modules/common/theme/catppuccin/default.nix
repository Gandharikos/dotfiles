{
  lib,
  config,
  inputs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.my.theme.catppuccin;
  flavorName = lib.toSentenceCase cfg.flavor;
  rawPalette =
    (lib.importJSON "${config.catppuccin.sources.palette}/palette.json").${cfg.flavor}.colors;
  palette = lib.mapAttrs (_: color: color.hex) rawPalette;
in
{
  config = mkIf cfg.enable {
    my.theme = {
      wallpaper = inputs.wallpapers.catppuccin.rocket-launch.path;
      colorscheme = {
        inherit palette;
        slug = "catppuccin-${cfg.flavor}-${cfg.accent}";
        name = "Catppuccin ${flavorName}";
        description = "A soothing pastel color scheme by Catppuccin.";
        author = "Catppuccin";
      };
    };
  };
}
