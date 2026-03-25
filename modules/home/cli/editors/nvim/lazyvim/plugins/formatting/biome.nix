{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.biome;
in
{
  options.my.lazyvim.biome = {
    enable = mkEnableOption "formatting tool - biome";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      imports = [ "lazyvim.plugins.extras.formatting.biome" ];

      extraPackages = with pkgs; [
        biome
      ];
    };
  };
}
