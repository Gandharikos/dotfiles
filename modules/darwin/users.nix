{ config, ... }:
let
  inherit (config.networking) hostName;
in
{
  networking.computerName = hostName;
  system.primaryUser = config.dot.name;
}
