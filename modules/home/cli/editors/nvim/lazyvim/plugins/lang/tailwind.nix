{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.tailwind;
in
{
  options.my.neovim.lazyvim.tailwind = {
    enable = mkEnableOption "language tailwind";
  };

  config = mkIf cfg.enable {
    /*
         my.neovim.lazyvim.extraPlugins = with pkgs.vimPlugins; [
        tailwindcss-colorizer-cmp-nvim
      ];
    */
    my.neovim.lazyvim = {
      imports = [ "lazyvim.plugins.extras.lang.tailwind" ];

      extraPackages = with pkgs; [
        tailwindcss
      ];
    };
  };
}
