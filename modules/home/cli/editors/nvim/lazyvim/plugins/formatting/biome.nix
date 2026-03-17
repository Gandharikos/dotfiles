{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.biome;
in
{
  options.my.neovim.lazyvim.biome = {
    enable = mkEnableOption "formatting tool - biome";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      imports = [ "lazyvim.plugins.extras.formatting.biome" ];

      extraPackages = with pkgs; [
        biome
      ];
    };
  };
}
