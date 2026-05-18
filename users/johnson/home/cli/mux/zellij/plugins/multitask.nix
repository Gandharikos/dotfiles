{
  config,
  pkgs,
  ...
}:
let
  multitask = "${pkgs.dot.multitask}/bin/multitask.wasm";
  shell = "${config.home.profileDirectory}/bin/${config.my.shell}";
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
