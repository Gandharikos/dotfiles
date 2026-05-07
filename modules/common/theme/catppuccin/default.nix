{
  lib,
  config,
  inputs,
  themeNamespace ? "dot",
  ...
}:
let
  inherit (lib.modules) mkIf;
  namespace = themeNamespace;
  cfg = config.${namespace}.theme.catppuccin;
  flavorName = lib.toSentenceCase cfg.flavor;
  rawPalette =
    (lib.importJSON "${config.catppuccin.sources.palette}/palette.json").${cfg.flavor}.colors;
  palette = lib.mapAttrs (_: color: color.hex) rawPalette;
in
{
  config = mkIf cfg.enable {
    ${namespace}.theme = {
      wallpaper = inputs.wallpapers.catppuccin.anime-japan.path;
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
