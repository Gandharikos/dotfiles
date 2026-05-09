{
  self,
  self',
  inputs,
  inputs',
  pkgs,
  pkgs',
  lib,
  config,
  _class,
  ...
}:
let
  extraSpecialArgs = {
    inherit
      self
      self'
      inputs
      inputs'
      pkgs
      pkgs'
      lib
      ;
    osClass = _class;
    themeNamespace = "my";
  };
  inherit (config) dot;
  inherit (lib.attrsets) genAttrs optionalAttrs removeAttrs;
  primaryHomeModule =
    user: _:
    let
      userCfg = dot.users.${user};
      themeInput =
        removeAttrs userCfg.theme [
          "avatar"
          "colorscheme"
          "cursor"
          "wallpaper"
        ]
        // optionalAttrs (userCfg.theme.avatar != null) {
          inherit (userCfg.theme) avatar;
        }
        // optionalAttrs (userCfg.theme.cursor != null) {
          inherit (userCfg.theme) cursor;
        }
        // optionalAttrs (userCfg.theme.wallpaper != null) {
          inherit (userCfg.theme) wallpaper;
        };
    in
    {
      imports = [ userCfg.home ];
      my =
        (removeAttrs userCfg [
          "home"
          "persistence"
          "theme"
        ])
        // {
          theme = themeInput;
        };
    };
in
{
  home-manager = {
    inherit extraSpecialArgs;
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    useUserPackages = true;
    verbose = true;
    users = genAttrs dot.enabledUser primaryHomeModule;
    sharedModules = [ ../home ];
  };
}
