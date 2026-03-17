{ lib, ... }:
{
  imports = lib.my.scanPaths ./.;
  programs.zellij.settings.plugins = {
    compact-bar = {
      _props = {
        location = "zellij:compact-bar";
      };
      tooltip = "F1";
    };
  };
}
