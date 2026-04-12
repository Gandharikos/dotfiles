{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (config.my) gui;
in
{
  imports = lib.my.scanPaths ./.;

  config = mkIf gui.enable {
    home.packages = with pkgs; [
      calibre
      teams-for-linux
    ];
  };
}
