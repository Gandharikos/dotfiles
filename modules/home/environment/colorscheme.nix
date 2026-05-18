{ inputs, lib, ... }:
{
  imports = [
    inputs.nixporn.homeModules.colorscheme
  ];

  nixporn = {
    enable = true;
    kvantum.enable = lib.mkDefault false;
    qt5ct.enable = lib.mkDefault false;
    spicetify.enable = lib.mkDefault false;
    starship.enable = lib.mkDefault false;
    tmux.enable = lib.mkDefault false;
    zellij.enable = lib.mkDefault false;
  };
}
