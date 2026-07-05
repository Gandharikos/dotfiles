{
  inputs,
  lib,
  config,
  osConfig ? null,
  ...
}:
let
  inherit (lib.modules)
    mkDefault
    mkIf
    mkMerge
    ;

  hasSystemTheme = osConfig != null && osConfig ? nixporn;
  colorschemeName = config.nixporn.colorscheme;
in
{
  imports = [
    inputs.nixporn.homeModules.colorscheme
  ];

  config = mkMerge [
    {
      nixporn = {
        enable = true;
        gemini-cli.enable = false;
      };
    }
    (mkIf hasSystemTheme {
      nixporn = {
        colorscheme = mkDefault osConfig.nixporn.colorscheme;
        transparent = mkDefault osConfig.nixporn.transparent;

        colorschemes = {
          catppuccin = {
            accent = mkDefault osConfig.nixporn.colorschemes.catppuccin.accent;
            flavor = mkDefault osConfig.nixporn.colorschemes.catppuccin.flavor;
          };
          tokyonight.style = mkDefault osConfig.nixporn.colorschemes.tokyonight.style;
        };
      };
    })
    (mkIf (!hasSystemTheme) {
      nixporn = {
        colorscheme = mkDefault "tokyonight";
        transparent = mkDefault true;
      };
    })
    (mkIf (colorschemeName != null) {
      home.sessionVariables = {
        COLORSCHEME = config.nixporn.colorschemes.${colorschemeName}.slug;
        COLORSCHEME_NAME = colorschemeName;
      };
    })
  ];
}
