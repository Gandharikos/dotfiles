{ config, lib, ... }:
let
  inherit (lib.modules) mkIf;
  name = config.dot.networking.proxy.clashVerge.enabledUser;
in
{
  config = mkIf (name != null) {
    programs.clash-verge = {
      enable = true;
      serviceMode = true;
      tunMode = true;
      group = "clash-verge";
    };

    users.groups.clash-verge = { };
    users.users.${name}.extraGroups = [ "clash-verge" ];
  };
}
