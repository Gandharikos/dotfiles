{ config, ... }:
let
  inherit (config.home) homeDirectory;
in
{
  sops.secrets.u2f_keys.path = "${homeDirectory}/.config/Yubico/u2f_keys";
}
