{
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (lib.dot) scanPaths;
  inherit (lib.modules)
    mkDefault
    mkIf
    mkMerge
    ;

  colorschemeName = config.nixporn.colorscheme;
in
{
  imports = [
    inputs.nixporn.homeModules.colorscheme
  ]
  ++ scanPaths ./.;

  config = mkMerge [
    {
      nixporn = {
        enable = mkDefault true;
        colorscheme = mkDefault "tokyonight";
        transparent = mkDefault true;
      };
    }
    (mkIf (colorschemeName != null) {
      home.sessionVariables = {
        COLORSCHEME = config.nixporn.colorschemes.${colorschemeName}.slug;
        COLORSCHEME_NAME = colorschemeName;
      };
    })
  ];
}
