{
  lib,
  config,
  ...
}:
{
  imports = lib.dot.scanPaths ./.;

  programs.zellij = {
    settings.default_layout = lib.mkForce "default";
    layouts.default.layout._children = [
      config.dot.zellij.template
    ];
  };
}
