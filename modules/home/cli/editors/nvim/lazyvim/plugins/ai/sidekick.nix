{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.sidekick;
in
{
  options.my.neovim.lazyvim.sidekick = {
    enable = mkEnableOption "AI plugin - sidekick";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        sidekick-nvim
      ];

      config = [ "ai/sidekick.lua" ];
    };
  };
}
