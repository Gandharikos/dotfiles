{
  lib,
  config,
  osConfig,
  ...
}:
let
  inherit (lib.dot) scanPaths;
  inherit (lib.modules) mkDefault mkIf mkMerge;
  inherit (osConfig.dot) theme;
in
{
  imports = [
    ../../common/theme
  ]
  ++ scanPaths ./.;

  config = mkMerge [
    {
      my.theme = {
        avatar = mkDefault theme.avatar;
        cursor = mkDefault theme.cursor;
      };
    }
    (mkIf (config.my.theme.default != null) {
      home.sessionVariables = {
        COLORSCHEME = config.my.theme.colorscheme.slug;
        COLORSCHEME_NAME = config.my.theme.default;
      };
    })
  ];
}
