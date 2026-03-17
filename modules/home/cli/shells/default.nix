{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.meta) getExe;
  curl' = getExe pkgs.curl;
in
{
  imports = lib.my.scanPaths ./.;
  config.home = {
    shellAliases = {
      weather = "${curl'} wttr.in";
    };
    sessionVariables.KEYBOARD_LAYOUT = config.my.keyboard.layout;
  };
}
