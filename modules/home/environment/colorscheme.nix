{ inputs, ... }:
{
  imports = [
    inputs.nixporn.homeModules.colorscheme
  ];

  nixporn = {
    enable = true;
  };
}
