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
  };
  inherit (config) dot;
  inherit (lib.attrsets) genAttrs removeAttrs;
  primaryHomeModule =
    user: _:
    let
      userCfg = dot.users.${user};
    in
    {
      imports = [ userCfg.home ];
      my = removeAttrs userCfg [
        "home"
        "persistence"
      ];
    };
in
{
  home-manager = {
    inherit extraSpecialArgs;
    # backupFileExtension = "backup";
    backupCommand = lib.getExe' pkgs.trash-cli "trash-put";
    useGlobalPkgs = true;
    useUserPackages = true;
    verbose = true;
    users = genAttrs dot.enabledUsers primaryHomeModule;
    sharedModules = [ ../home ];
  };
}
