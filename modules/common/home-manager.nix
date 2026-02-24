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
}: let
  inherit (config.networking) hostName;
  extraSpecialArgs = {
    inherit self self' inputs inputs' pkgs pkgs' lib hostName;
    system = _class;
  };
  inherit (config) my;
in {
  imports = [
    (lib.mkAliasOptionModule ["hm"] ["home-manager" "users" config.my.name])
  ];

  hm = {
    imports = [../home];
    my = {
      inherit (my) name fullName email shell home keyboard theme persistence;

      # We do not inherit `my` directly from `config` because NixOS declares options that should not flow into home-manager.
      machine = {
        inherit (my.machine) type gpu cpu monitors hasHidpi;
      };
      desktop = {
        inherit (my.desktop) enable type default exec;
      };

      security = {
        inherit (my.security) enable;
      };
    };
  };

  home-manager = {
    inherit extraSpecialArgs;
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    # FIXME: this is not work
    useUserPackages = true;
  };
}
