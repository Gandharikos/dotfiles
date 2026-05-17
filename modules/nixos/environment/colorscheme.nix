{
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (lib.dot) relativeToConfig;
  inherit (lib.modules) mkDefault;
in
{
  imports = [
    inputs.nixporn.nixosModules.colorscheme
  ];

  nixporn = {
    enable = mkDefault true;
    colorscheme = mkDefault "tokyonight";
    transparent = mkDefault true;
    avatar = mkDefault (if config.dot.gui.enable then relativeToConfig "avatars/makima.jpg" else null);
    wallpaper = mkDefault null;
  };
}
