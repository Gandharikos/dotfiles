{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.neovim.lazyvim.tabnine;
in
{
  options.my.neovim.lazyvim.tabnine = {
    enable = mkEnableOption "AI plugin - tabnine";
  };

  config = mkIf cfg.enable {
    my.neovim.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        cmp-tabnine
      ];

      imports = [ "lazyvim.plugins.extras.ai.tabnine" ];
    };
    # my.neovim.lazyvim.extraPackages = with pkgs; [
    #   tabnine
    # ];
  };
}
