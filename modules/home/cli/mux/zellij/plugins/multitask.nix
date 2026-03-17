{
  lib,
  config,
  pkgs,
  ...
}:
let
  multitask = "${pkgs.my.multitask}/bin/multitask.wasm";
  inherit (lib.meta) getExe;
  shell = getExe (builtins.getAttr config.my.shell pkgs);
in
{
  programs.zellij.settings = {
    plugins.multitask = {
      _props.location = "file:${multitask}";
      _children = [
        {
          inherit shell;
        }
      ];
    };
  };
}
