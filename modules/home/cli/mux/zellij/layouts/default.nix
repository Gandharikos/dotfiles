{
  lib,
  config,
  ...
}:
{
  imports = lib.my.scanPaths ./.;

  programs.zellij = {
    settings.default_layout = lib.mkForce "default";
    layouts.default.layout._children = [
      config.my.zellij.template
    ];
  };
}
