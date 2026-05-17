{
  inputs,
  lib,
  ...
}:
{
  _class = "darwin";
  imports = (lib.dot.scanPaths ./.) ++ [
    inputs.nixporn.darwinModules.colorscheme
    ../common
  ];
}
