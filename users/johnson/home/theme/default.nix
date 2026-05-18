{
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
  imports = scanPaths ./.;

  config = mkMerge [
    {
      nixporn = {
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
