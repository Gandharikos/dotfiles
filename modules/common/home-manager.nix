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
in
{
  imports = [
    (lib.mkAliasOptionModule [ "hm" ] [ "home-manager" "users" config.dot.name ])
  ];

  hm = {
    imports = [ ../home ];
    dot = {
      inherit (dot)
        name
        fullName
        email
        shell
        home
        keyboard
        theme
        ;

      # We do not inherit `dot` directly from `config` because NixOS declares options that should not flow into home-manager.
      machine = {
        inherit (dot.machine)
          type
          gpu
          cpu
          monitors
          ;
      };
      gui = {
        inherit (dot.gui) enable;
        desktop = {
          inherit (dot.gui.desktop) type default exec;
        };
      };

      security = {
        inherit (dot.security) enable;
      };
    };
  };

  home-manager = {
    inherit extraSpecialArgs;
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    useUserPackages = true;
    verbose = true;

    # common options defined both user level and system level
    sharedModules = [ ./dot ];
  };
}
