{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.tailwind;
in
{
  options.my.lazyvim.tailwind = {
    enable = mkEnableOption "language tailwind";
  };

  config = mkIf cfg.enable {
    /*
         my.lazyvim.extraPlugins = with pkgs.vimPlugins; [
        tailwindcss-colorizer-cmp-nvim
      ];
    */
    my.lazyvim = {
      imports = [ "lazyvim.plugins.extras.lang.tailwind" ];

      extraPackages = with pkgs; [
        tailwindcss
      ];
    };
  };
}
