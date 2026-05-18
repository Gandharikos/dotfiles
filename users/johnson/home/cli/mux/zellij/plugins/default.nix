{ lib, ... }:
{
  imports = lib.dot.scanPaths ./.;
  programs.zellij.settings.plugins = {
    compact-bar = {
      _props = {
        location = "zellij:compact-bar";
      };
      tooltip = "F1";
    };
  };
}
